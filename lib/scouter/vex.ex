defmodule Scouter.Vex do
  require Logger

  alias Scouter.Repo
  alias Scouter.Scouting.Event

  @base_url "https://events.vex.com/api/v2"

  def fetch_events(season_id, region) do
    fetch_events(season_id, region, 1, [])
  end

  defp fetch_events(season_id, region, page, acc) do
    resp =
      Req.get!("#{@base_url}/events",
        auth: {:bearer, System.get_env("ROBOTEVENTS_API_KEY")},
        params: [{"season[]", season_id}, {"region", region}, {"page", page}]
      )

    case resp.status do
      200 ->
        events = resp.body["data"]
        total_pages = resp.body["meta"]["last_page"]
        acc = acc ++ events

        if page < total_pages do
          fetch_events(season_id, region, page + 1, acc)
        else
          acc
        end

      status ->
        Logger.error(
          "VEX events fetch failed with status #{status}, returning #{length(acc)} events fetched so far"
        )

        acc
    end
  end

  def upsert_events(raw_events) do
    raw_events
    |> Enum.reject(&String.starts_with?(&1["name"], "[PREVIEW]"))
    |> Enum.map(fn raw ->
      attrs = %{
        vex_id: raw["id"],
        sku: raw["sku"],
        name: raw["name"],
        date: raw["start"] |> String.slice(0, 10) |> Date.from_iso8601!(),
        region: raw["location"]["region"]
      }

      %Event{}
      |> Event.changeset(attrs)
      |> Repo.insert!(
        on_conflict: {:replace, [:sku, :name, :date, :region, :updated_at]},
        conflict_target: :vex_id
      )
    end)
  end

  alias Scouter.Scouting.{Team, EventTeam}

  def fetch_teams(event_vex_id) do
    fetch_teams(event_vex_id, 1, [])
  end

  defp fetch_teams(event_vex_id, page, acc) do
    resp =
      Req.get!("#{@base_url}/events/#{event_vex_id}/teams",
        auth: {:bearer, System.get_env("ROBOTEVENTS_API_KEY")},
        params: [{"page", page}]
      )

    case resp.status do
      200 ->
        teams = resp.body["data"]
        total_pages = resp.body["meta"]["last_page"]
        acc = acc ++ teams

        if page < total_pages do
          fetch_teams(event_vex_id, page + 1, acc)
        else
          acc
        end

      status ->
        Logger.error("VEX teams fetch failed with status #{status} for event #{event_vex_id}")
        acc
    end
  end

  def upsert_event_teams(event, raw_teams) do
    Enum.each(raw_teams, fn raw ->
      team =
        %Team{}
        |> Team.changeset(%{
          vex_id: raw["id"],
          number: raw["number"],
          name: raw["team_name"],
          organization: raw["organization"]
        })
        |> Repo.insert!(
          on_conflict: {:replace, [:name, :number, :organization, :updated_at]},
          conflict_target: :vex_id
        )

      %EventTeam{}
      |> Ecto.Changeset.change(%{event_id: event.id, team_id: team.id})
      |> Repo.insert!(on_conflict: :nothing, conflict_target: [:event_id, :team_id])
    end)
  end

  def fetch_rankings(event_vex_id, division_id) do
    fetch_rankings(event_vex_id, division_id, 1, [])
  end

  defp fetch_rankings(event_vex_id, division_id, page, acc) do
    resp =
      Req.get!("#{@base_url}/events/#{event_vex_id}/divisions/#{division_id}/rankings",
        auth: {:bearer, System.get_env("ROBOTEVENTS_API_KEY")},
        params: [{"page", page}]
      )

    case resp.status do
      200 ->
        rankings = resp.body["data"]
        total_pages = resp.body["meta"]["last_page"]
        acc = acc ++ rankings

        if page < total_pages do
          fetch_rankings(event_vex_id, division_id, page + 1, acc)
        else
          acc
        end

      status ->
        Logger.error(
          "VEX rankings fetch failed with status #{status} for event #{event_vex_id}, division #{division_id}"
        )

        acc
    end
  end

  def upsert_rankings(event, raw_rankings) do
    Enum.each(raw_rankings, fn raw ->
      team = Repo.get_by(Team, vex_id: raw["team"]["id"])
      event_team = team && Repo.get_by(EventTeam, event_id: event.id, team_id: team.id)

      if event_team do
        event_team
        |> EventTeam.ranking_changeset(%{
          wins: raw["wins"],
          losses: raw["losses"],
          ties: raw["ties"],
          rank: raw["rank"],
          win_points: raw["wp"],
          autonomous_points: raw["ap"],
          strength_of_schedule_points: raw["sp"]
        })
        |> Repo.update!()
      end
    end)
  end

  def fetch_skills(event_vex_id) do
    fetch_skills(event_vex_id, 1, [])
  end

  defp fetch_skills(event_vex_id, page, acc) do
    resp =
      Req.get!("#{@base_url}/events/#{event_vex_id}/skills",
        auth: {:bearer, System.get_env("ROBOTEVENTS_API_KEY")},
        params: [{"page", page}]
      )

    case resp.status do
      200 ->
        skills = resp.body["data"]
        total_pages = resp.body["meta"]["last_page"]
        acc = acc ++ skills

        if page < total_pages do
          fetch_skills(event_vex_id, page + 1, acc)
        else
          acc
        end

      status ->
        Logger.error("VEX skills fetch failed with status #{status} for event #{event_vex_id}")
        acc
    end
  end

  def upsert_skills(event, raw_skills) do
    Enum.each(raw_skills, fn raw ->
      team = Repo.get_by(Team, vex_id: raw["team"]["id"])
      event_team = team && Repo.get_by(EventTeam, event_id: event.id, team_id: team.id)

      attrs =
        case raw["type"] do
          "driver" -> %{driver_skills: raw["score"]}
          "programming" -> %{programming_skills: raw["score"]}
          _ -> %{}
        end

      if event_team && attrs != %{} do
        event_team
        |> EventTeam.skills_changeset(attrs)
        |> Repo.update!()
      end
    end)
  end

  def sync(season_id, region) do
    raw_events = fetch_events(season_id, region)
    saved_events = upsert_events(raw_events)

    Enum.zip(raw_events, saved_events)
    |> Enum.each(fn {raw_event, event} ->
      raw_teams = fetch_teams(event.vex_id)
      upsert_event_teams(event, raw_teams)

      Enum.each(raw_event["divisions"], fn division ->
        raw_rankings = fetch_rankings(event.vex_id, division["id"])
        upsert_rankings(event, raw_rankings)
      end)

      raw_skills = fetch_skills(event.vex_id)
      upsert_skills(event, raw_skills)
    end)
  end
end
