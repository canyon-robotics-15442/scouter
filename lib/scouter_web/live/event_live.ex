defmodule ScouterWeb.EventLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{Event, EventTeam, Analysis}

  def mount(%{"vex_id" => vex_id}, _session, socket) do
    event = Repo.get_by!(Event, vex_id: vex_id)

    event_teams =
      Repo.all(from et in EventTeam, where: et.event_id == ^event.id, preload: :team)
      |> Enum.sort_by(&{&1.rank == nil, &1.rank, team_number_sort_key(&1.team.number)})

    scored = Enum.filter(event_teams, &(&1.wins || &1.driver_skills || &1.programming_skills))
    enough_scored? = scored != [] and length(scored) * 2 >= length(event_teams)

    difficulty =
      case enough_scored? do
        false ->
          nil

        true ->
          scored
          |> Enum.map(
            &%{
              wins: &1.wins,
              losses: &1.losses,
              ties: &1.ties,
              driver_skills: &1.driver_skills,
              programming_skills: &1.programming_skills
            }
          )
          |> Analysis.event_difficulty()
      end

    skills_teams =
      event_teams
      |> Enum.filter(&(&1.driver_skills || &1.programming_skills))
      |> Enum.sort_by(&((&1.driver_skills || 0) + (&1.programming_skills || 0)), :desc)
      |> Enum.with_index(1)

    {:ok,
     assign(socket,
       event: event,
       event_teams: event_teams,
       skills_teams: skills_teams,
       difficulty: difficulty
     )}
  end

  defp team_number_sort_key(number) do
    case Regex.run(~r/^(\d+)(.*)$/, number) do
      [_, digits, suffix] -> {String.to_integer(digits), suffix}
      nil -> {0, number}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <.link navigate={~p"/events"} class="text-sm text-base-content/50 hover:text-base-content">← Back</.link>

      <section class="grid grid-cols-2 gap-14 items-end pt-9 pb-14 border-b border-base-300">
        <div>
          <div class="text-[11px] tracking-widest uppercase text-primary">{@event.date} · {@event.region}</div>
          <h1 class="mt-5 text-4xl leading-[1.05] tracking-tighter font-bold">{@event.name}</h1>
          <.link
            href={"https://events.vex.com/robot-competitions/vex-robotics-competition/#{@event.sku}.html"}
            target="_blank"
            class="mt-4 inline-block text-sm text-base-content/50 hover:text-base-content"
          >View on VEX Events →</.link>
        </div>
        <div class="bg-base-200 p-6">
          <div class="text-[10.5px] tracking-widest uppercase text-base-content/50">
            Expected difficulty
          </div>
          <div :if={@difficulty} class="mt-3 text-5xl font-bold tracking-tighter text-primary">
            {@difficulty}
          </div>
          <div :if={!@difficulty} class="mt-3 text-2xl text-base-content/50">
            No ranking data yet
          </div>
        </div>
      </section>

      <section class="py-14">
        <h2 class="text-[13px] tracking-widest uppercase text-base-content/50 mb-7">Alliance matches</h2>
        <div class="grid grid-cols-[110px_1fr_340px] gap-5 pb-1 border-b border-base-300 text-[10.5px] tracking-widest uppercase text-base-content/50">
          <span>Number</span><span>Name</span><span class="text-right">Record</span>
        </div>
        <div class="pb-3.5 text-right text-[10.5px] text-base-content/40">W–L–T · WP · AP · SP</div>
        <div
          :for={et <- @event_teams}
          class="grid grid-cols-[110px_1fr_340px] gap-5 py-4 border-b border-base-300 items-center"
        >
          <.link navigate={~p"/teams/#{et.team.number}"} class={["text-sm link link-hover", (et.team.favorite && "text-error") || "text-primary"]}>{et.team.number}</.link>
          <span class="text-[15px]">{et.team.name}</span>
          <span :if={et.rank} class="text-sm text-right text-base-content/70">
            Rank {et.rank} · {et.wins}-{et.losses}-{et.ties} · {et.win_points || "—"} WP · {et.autonomous_points || "—"} AP · {et.strength_of_schedule_points || "—"} SP
          </span>
          <span :if={!et.rank} class="text-sm text-right text-base-content/50">No results yet</span>
        </div>
      </section>

      <section class="py-14 border-t border-base-300">
        <h2 class="text-[13px] tracking-widest uppercase text-base-content/50 mb-7">Skills matches</h2>
        <div :if={@skills_teams == []} class="py-10 text-base-content/50">
          No skills results yet.
        </div>
        <div :if={@skills_teams != []}>
          <div class="grid grid-cols-[60px_110px_1fr_140px_140px_140px] gap-5 pb-3.5 border-b border-base-300 text-[10.5px] tracking-widest uppercase text-base-content/50">
            <span>Rank</span><span>Number</span><span>Name</span>
            <span class="text-right">Driver</span><span class="text-right">Programming</span>
            <span class="text-right">Combined</span>
          </div>
          <div
            :for={{et, rank} <- @skills_teams}
            class="grid grid-cols-[60px_110px_1fr_140px_140px_140px] gap-5 py-4 border-b border-base-300 items-center"
          >
            <span class="text-sm text-base-content/50">{rank}</span>
            <.link navigate={~p"/teams/#{et.team.number}"} class={["text-sm link link-hover", (et.team.favorite && "text-error") || "text-primary"]}>{et.team.number}</.link>
            <span class="text-[15px]">{et.team.name}</span>
            <span class="text-sm text-right text-base-content/70">{et.driver_skills || "—"}</span>
            <span class="text-sm text-right text-base-content/70">{et.programming_skills || "—"}</span>
            <span class="text-sm text-right font-bold">{(et.driver_skills || 0) + (et.programming_skills || 0)}</span>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
