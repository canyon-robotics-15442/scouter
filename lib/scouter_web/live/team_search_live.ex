defmodule ScouterWeb.TeamSearchLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{Team, EventTeam, Event}

  def mount(params, _session, socket) do
    query = params["q"] || ""

    {:ok, assign(socket, query: query, teams: search(query))}
  end

  defp search(query) do
    trimmed = String.trim(query)

    if trimmed == "" do
      []
    else
      like = "%#{trimmed}%"

      from(t in Team,
        join: et in EventTeam,
        on: et.team_id == t.id,
        join: e in Event,
        on: e.id == et.event_id,
        where: e.region == "California",
        where: ilike(t.number, ^like) or ilike(t.name, ^like),
        distinct: t.id,
        order_by: t.number
      )
      |> Repo.all()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <h1 class="text-5xl font-bold tracking-tight leading-none mb-11">
        Search results for "{@query}"
      </h1>
      <div class="text-[11px] tracking-widest uppercase text-base-content/50 mb-7">
        California — Region 4
      </div>

      <div :if={@teams == []} class="py-10 text-base-content/50">No teams found.</div>

      <div :for={team <- @teams} class="py-4 border-b border-base-300 flex items-baseline gap-5">
        <.link navigate={~p"/teams/#{team.number}"} class="text-lg text-primary link link-hover">{team.number}</.link>
        <span class="text-base-content/70">{team.name}</span>
      </div>
    </div>
    """
  end
end
