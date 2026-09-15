defmodule ScouterWeb.SkillsLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{Team, EventTeam}

  @our_teams ~w(15442A 15442B 15442D 15442X)

  def mount(_params, _session, socket) do
    rankings =
      from(et in EventTeam,
        join: t in Team,
        on: t.id == et.team_id,
        where: not is_nil(et.driver_skills) or not is_nil(et.programming_skills),
        group_by: [t.id, t.number, t.name, t.favorite],
        select: %{
          number: t.number,
          name: t.name,
          favorite: t.favorite,
          driver: max(et.driver_skills),
          programming: max(et.programming_skills)
        }
      )
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :combined, (&1.driver || 0) + (&1.programming || 0)))
      |> Enum.sort_by(& &1.combined, :desc)
      |> Enum.with_index(1)

    {:ok, assign(socket, rankings: rankings)}
  end

  defp ours?(number), do: number in @our_teams

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <div class="flex items-end justify-between gap-10 mb-11">
        <h1 class="text-5xl font-bold tracking-tight leading-none">Skills rankings</h1>
        <div class="text-[11px] tracking-widest uppercase text-base-content/50">
          California — Region 4
        </div>
      </div>

      <div :if={@rankings == []} class="py-20 text-center text-base-content/50">
        No skills results synced yet.
      </div>

      <div :if={@rankings != []}>
        <div class="grid grid-cols-[60px_110px_1fr_140px_140px_140px] gap-5 pb-3.5 border-b border-base-300 text-[10.5px] tracking-widest uppercase text-base-content/50">
          <span>Rank</span><span>Team</span><span>Name</span>
          <span class="text-right">Driver</span><span class="text-right">Programming</span>
          <span class="text-right">Combined</span>
        </div>
        <div
          :for={{row, rank} <- @rankings}
          class={[
            "grid grid-cols-[60px_110px_1fr_140px_140px_140px] gap-5 py-4 border-b border-base-300 items-center",
            ours?(row.number) && "bg-primary/10"
          ]}
        >
          <span class="text-sm text-base-content/50">{rank}</span>
          <.link
            navigate={~p"/teams/#{row.number}"}
            class={["text-sm link link-hover", (row.favorite && "text-error") || "text-primary"]}
          >{row.number}</.link>
          <span class="text-[15px]">{row.name}</span>
          <span class="text-sm text-right text-base-content/70">{row.driver || "—"}</span>
          <span class="text-sm text-right text-base-content/70">{row.programming || "—"}</span>
          <span class="text-sm text-right font-bold">{row.combined}</span>
        </div>
      </div>
    </div>
    """
  end
end
