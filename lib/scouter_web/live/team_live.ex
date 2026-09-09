defmodule ScouterWeb.TeamLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{Team, EventTeam, Analysis}

  def mount(%{"number" => number}, _session, socket) do
    team = Repo.get_by!(Team, number: number)

    event_teams =
      Repo.all(from et in EventTeam, where: et.team_id == ^team.id, preload: :event)
      |> Enum.sort_by(& &1.event.date)

    scored = Enum.filter(event_teams, &(&1.wins && &1.losses))

    overall_score =
      case scored do
        [] ->
          nil

        _ ->
          scored
          |> Enum.map(&Analysis.team_strength(%{wins: &1.wins, losses: &1.losses}))
          |> Enum.sum()
          |> div(length(scored))
      end

    {:ok, assign(socket, team: team, event_teams: event_teams, overall_score: overall_score)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <.link navigate={~p"/events"} class="text-sm text-base-content/50 hover:text-base-content">← Back</.link>

      <section class="grid grid-cols-2 gap-14 items-end pt-9 pb-14 border-b border-base-300">
        <div>
          <div class="text-[11px] tracking-widest uppercase text-primary">V5RC</div>
          <h1 class="mt-5 text-8xl leading-[0.9] tracking-tighter font-bold">{@team.number}</h1>
          <div class="mt-4 text-2xl tracking-tight text-base-content/70">{@team.name}</div>
        </div>
        <div class="bg-base-200 p-6">
          <div class="text-[10.5px] tracking-widest uppercase text-base-content/50">
            Overall score
          </div>
          <div :if={@overall_score} class="mt-3 text-5xl font-bold tracking-tighter text-primary">
            {@overall_score}
          </div>
          <div :if={!@overall_score} class="mt-3 text-2xl text-base-content/50">
            No ranking data yet
          </div>
        </div>
      </section>

      <section class="py-14">
        <h2 class="text-[13px] tracking-widest uppercase text-base-content/50 mb-7">Tournaments</h2>
        <div class="grid grid-cols-[110px_1fr_220px] gap-5 pb-3.5 border-b border-base-300 text-[10.5px] tracking-widest uppercase text-base-content/50">
          <span>Date</span><span>Event</span><span class="text-right">Record</span>
        </div>
        <div
          :for={et <- @event_teams}
          class="grid grid-cols-[110px_1fr_220px] gap-5 py-4 border-b border-base-300 items-center"
        >
          <span class="text-sm text-base-content/50">{et.event.date}</span>
          <span class="text-[15px]">{et.event.name}</span>
          <span :if={et.rank} class="text-sm text-right text-base-content/70">Rank {et.rank} · {et.wins}-{et.losses}-{et.ties}</span>
          <span :if={!et.rank} class="text-sm text-right text-base-content/50">No results yet</span>
        </div>
      </section>
    </div>
    """
  end
end
