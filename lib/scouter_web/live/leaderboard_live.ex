defmodule ScouterWeb.LeaderboardLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{EventTeam, Analysis}

  @our_teams ~w(15442A 15442B 15442D 15442X)

  def mount(_params, _session, socket) do
    rankings =
      Repo.all(from et in EventTeam, preload: [:team, :event])
      |> Enum.filter(&(&1.wins || &1.driver_skills || &1.programming_skills))
      |> Enum.group_by(& &1.team)
      |> Enum.map(fn {team, event_teams} ->
        entries =
          Enum.map(event_teams, fn et ->
            %{
              wins: et.wins,
              losses: et.losses,
              ties: et.ties,
              driver_skills: et.driver_skills,
              programming_skills: et.programming_skills,
              date: et.event.date
            }
          end)

        %{team: team, score: Analysis.recency_weighted_strength(entries)}
      end)
      |> Enum.sort_by(& &1.score, :desc)
      |> Enum.with_index(1)

    {:ok, assign(socket, rankings: rankings)}
  end

  defp ours?(number), do: number in @our_teams

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <div class="flex items-end justify-between gap-10 mb-11">
        <h1 class="text-5xl font-bold tracking-tight leading-none">Leaderboard</h1>
        <div class="text-[11px] tracking-widest uppercase text-base-content/50">
          California — Region 4
        </div>
      </div>

      <div :if={@rankings == []} class="py-20 text-center text-base-content/50">
        No scored teams yet.
      </div>

      <div :if={@rankings != []}>
        <div class="grid grid-cols-[60px_110px_1fr_140px] gap-5 pb-3.5 border-b border-base-300 text-[10.5px] tracking-widest uppercase text-base-content/50">
          <span>Rank</span><span>Team</span><span>Name</span>
          <span class="text-right">Score</span>
        </div>
        <div
          :for={{row, rank} <- @rankings}
          class={[
            "grid grid-cols-[60px_110px_1fr_140px] gap-5 py-4 border-b border-base-300 items-center",
            ours?(row.team.number) && "bg-primary/10"
          ]}
        >
          <span class="text-sm text-base-content/50">{rank}</span>
          <.link
            navigate={~p"/teams/#{row.team.number}"}
            class={["text-sm link link-hover", (row.team.favorite && "text-error") || "text-primary"]}
          >{row.team.number}</.link>
          <span class="text-[15px]">{row.team.name}</span>
          <span class="text-sm text-right font-bold">{Float.round(row.score, 1)}</span>
        </div>
      </div>
    </div>
    """
  end
end
