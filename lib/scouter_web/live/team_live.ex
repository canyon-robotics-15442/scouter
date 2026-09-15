defmodule ScouterWeb.TeamLive do
  use ScouterWeb, :live_view
  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.{Team, EventTeam, ScoutingNote, Analysis}

  def mount(%{"number" => number}, session, socket) do
    team = Repo.get_by!(Team, number: number)
    current_user = session["current_user"]

    notes =
      Repo.all(from n in ScoutingNote, where: n.team_id == ^team.id, order_by: [desc: n.inserted_at])

    event_teams =
      Repo.all(from et in EventTeam, where: et.team_id == ^team.id, preload: :event)
      |> Enum.sort_by(& &1.event.date, Date)

    scored = Enum.filter(event_teams, &(&1.wins || &1.driver_skills || &1.programming_skills))

    overall_score =
      case scored do
        [] ->
          nil

        _ ->
          scored
          |> Enum.map(
            &%{
              wins: &1.wins,
              losses: &1.losses,
              ties: &1.ties,
              driver_skills: &1.driver_skills,
              programming_skills: &1.programming_skills,
              date: &1.event.date
            }
          )
          |> Analysis.recency_weighted_strength()
          |> round()
      end

    best_skills =
      if Enum.any?(event_teams, &(&1.driver_skills || &1.programming_skills)) do
        (event_teams |> Enum.map(&(&1.driver_skills || 0)) |> Enum.max()) +
          (event_teams |> Enum.map(&(&1.programming_skills || 0)) |> Enum.max())
      end

    {:ok,
     assign(socket,
       team: team,
       event_teams: event_teams,
       overall_score: overall_score,
       best_skills: best_skills,
       notes: notes,
       note_form: to_form(ScoutingNote.changeset(%ScoutingNote{}, %{})),
       current_user: current_user
     )}
  end

  def handle_event("save_note", %{"scouting_note" => params}, socket) do
    attrs =
      params
      |> Map.put("team_id", socket.assigns.team.id)
      |> Map.put("author_email", socket.assigns.current_user.email)

    case %ScoutingNote{} |> ScoutingNote.changeset(attrs) |> Repo.insert() do
      {:ok, note} ->
        {:noreply,
         assign(socket,
           notes: [note | socket.assigns.notes],
           note_form: to_form(ScoutingNote.changeset(%ScoutingNote{}, %{}))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, note_form: to_form(changeset))}
    end
  end

  def handle_event("toggle_favorite", _params, socket) do
    {:ok, team} =
      socket.assigns.team
      |> Team.favorite_changeset(%{favorite: !socket.assigns.team.favorite})
      |> Repo.update()

    {:noreply, assign(socket, team: team)}
  end

  def handle_event("delete_note", %{"id" => id}, socket) do
    note = Enum.find(socket.assigns.notes, &(&1.id == String.to_integer(id)))

    if note && note.author_email == socket.assigns.current_user.email do
      Repo.delete!(note)
      {:noreply, assign(socket, notes: Enum.reject(socket.assigns.notes, &(&1.id == note.id)))}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <.link navigate={~p"/events"} class="text-sm text-base-content/50 hover:text-base-content">← Back</.link>

      <section class="grid grid-cols-2 gap-14 items-end pt-9 pb-14 border-b border-base-300">
        <div>
          <div class="text-[11px] tracking-widest uppercase text-primary">V5RC</div>
          <h1 class="mt-5 text-8xl leading-[0.9] tracking-tighter font-bold">{@team.number}</h1>
          <div class="mt-4 flex items-center gap-3">
            <div class="text-2xl tracking-tight text-base-content/70">{@team.name}</div>
            <button
              phx-click="toggle_favorite"
              title={if @team.favorite, do: "Unfavorite", else: "Favorite"}
              class={[
                "text-2xl leading-none hover:opacity-70",
                (@team.favorite && "text-error") || "text-base-content/30"
              ]}
            >★</button>
          </div>
          <div :if={@team.organization} class="mt-1 text-sm text-base-content/50">{@team.organization}</div>
        </div>
        <div class="flex flex-col gap-4">
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
          <div class="bg-base-200 p-6">
            <div class="text-[10.5px] tracking-widest uppercase text-base-content/50">
              Best skills score
            </div>
            <div :if={@best_skills} class="mt-3 text-5xl font-bold tracking-tighter text-primary">
              {@best_skills}
            </div>
            <div :if={!@best_skills} class="mt-3 text-2xl text-base-content/50">
              N/A
            </div>
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
          <.link navigate={~p"/events/#{et.event.vex_id}"} class="text-[15px] text-primary link link-hover">{et.event.name}</.link>
          <span :if={et.rank} class="text-sm text-right text-base-content/70">Rank {et.rank} · {et.wins}-{et.losses}-{et.ties}</span>
          <span :if={!et.rank} class="text-sm text-right text-base-content/50">No results yet</span>
        </div>
      </section>

      <section class="py-14 border-t border-base-300">
        <h2 class="text-[13px] tracking-widest uppercase text-base-content/50 mb-7">Scouting notes</h2>

        <.form for={@note_form} phx-submit="save_note" class="flex flex-col gap-3 mb-10">
          <textarea
            name={@note_form[:body].name}
            class="textarea textarea-bordered w-full"
            rows="3"
            placeholder="What did you notice about this team?"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @note_form[:body].value) %></textarea>
          <button type="submit" class="btn btn-primary btn-sm self-start rounded-full">Add note</button>
        </.form>

        <div :if={@notes == []} class="py-6 text-base-content/50">No notes yet.</div>
        <div :for={note <- @notes} class="py-4 border-b border-base-300">
          <div class="flex items-start justify-between gap-4">
            <div class="text-[10.5px] tracking-widest uppercase text-base-content/50">
              {note.author_email} · {note.inserted_at}
            </div>
            <button
              :if={note.author_email == @current_user.email}
              phx-click="delete_note"
              phx-value-id={note.id}
              data-confirm="Delete this note?"
              class="text-[10.5px] tracking-widest uppercase text-base-content/50 hover:text-error"
            >Delete</button>
          </div>
          <p class="mt-2 text-[15px] whitespace-pre-wrap">{note.body}</p>
        </div>
      </section>
    </div>
    """
  end
end
