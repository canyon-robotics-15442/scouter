defmodule ScouterWeb.EventsLive do
  use ScouterWeb, :live_view

  import Ecto.Query

  alias Scouter.Repo
  alias Scouter.Scouting.Event

  def mount(_params, _session, socket) do
    events = Repo.all(from e in Event, order_by: e.date, preload: :teams)
    month = Date.beginning_of_month(Date.utc_today())

    {:ok, assign(socket, events: events, view_mode: :list, month: month)}
  end

  def handle_event("set_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: String.to_existing_atom(mode))}
  end

  def handle_event("prev_month", _params, socket) do
    {:noreply, assign(socket, month: shift_month(socket.assigns.month, -1))}
  end

  def handle_event("next_month", _params, socket) do
    {:noreply, assign(socket, month: shift_month(socket.assigns.month, 1))}
  end

  defp shift_month(date, offset) do
  total_months = date.year * 12 + (date.month - 1) + offset
  year = div(total_months, 12)
  month = rem(total_months, 12) + 1
  Date.new!(year, month, 1)
end

  defp calendar_weeks(month) do
    first = Date.beginning_of_month(month)
    last = Date.end_of_month(month)

    start_padding = Date.day_of_week(first, :sunday) - 1
    end_padding = 7 - Date.day_of_week(last, :sunday)

    days =
      List.duplicate(nil, start_padding) ++
        Enum.to_list(Date.range(first, last)) ++
        List.duplicate(nil, end_padding)

    Enum.chunk_every(days, 7)
  end

  defp events_on(nil, _events), do: []
  defp events_on(day, events), do: Enum.filter(events, &(&1.date == day))

def render(assigns) do
    ~H"""
    <div class="max-w-[1240px] mx-auto px-10 py-16">
      <div class="flex items-end justify-between gap-10 mb-11">
        <h1 class="text-5xl font-bold tracking-tight leading-none">Upcoming events</h1>
        <div class="flex gap-px bg-base-300 border border-base-300 rounded overflow-hidden">
          <button phx-click="set_view" phx-value-mode="list" class={["px-5 py-2.5 text-sm", @view_mode == :list && "bg-base-200" || "bg-base-100"]}>List</button>
          <button phx-click="set_view" phx-value-mode="calendar" class={["px-5 py-2.5 text-sm", @view_mode == :calendar && "bg-base-200" || "bg-base-100"]}>Calendar</button>
        </div>
      </div>

      <ul :if={@view_mode == :list}>
        <li :for={event <- @events} class="border-t border-base-300 py-4 first:border-t-0">
          <div class="flex items-baseline gap-5">
            <span class="text-xs uppercase tracking-wide text-primary w-20 shrink-0">{event.date}</span>
            <div>
              <div class="text-base">{event.name} <span class="text-base-content/50">({event.region})</span></div>
              <div class="mt-1 flex gap-2 text-xs">
                <.link :for={team <- event.teams} navigate={~p"/teams/#{team.number}"} class="link link-hover text-primary">{team.number}</.link>
              </div>
            </div>
          </div>
        </li>
      </ul>

      <div :if={@view_mode == :calendar}>
        <div class="flex items-center gap-5 mb-5">
          <button phx-click="prev_month" class="btn btn-sm btn-square btn-ghost border border-base-300">←</button>
          <div class="text-xl font-bold tracking-tight min-w-[180px]">{@month.year}-{@month.month}</div>
          <button phx-click="next_month" class="btn btn-sm btn-square btn-ghost border border-base-300">→</button>
        </div>

        <div class="grid grid-cols-7 gap-px bg-base-300 border border-base-300">
          <div :for={day_name <- ~w(Sun Mon Tue Wed Thu Fri Sat)} class="bg-base-100 px-3 py-2.5 text-[10.5px] tracking-widest uppercase text-base-content/50">
            {day_name}
          </div>

          <%= for week <- calendar_weeks(@month) do %>
            <%= for day <- week do %>
              <div class="bg-base-100 min-h-[110px] p-2.5">
                <div :if={day} class="text-xs font-bold">{day.day}</div>
                <div :for={event <- events_on(day, @events)} class="mt-2 bg-primary/10 border-l-2 border-primary rounded-sm px-2 py-1.5 text-[11px] leading-tight">
                  {event.name}
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
