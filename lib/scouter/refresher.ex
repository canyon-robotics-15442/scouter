defmodule Scouter.Refresher do
  use GenServer
  require Logger

  # Short interval for testing — we'll bump this up once it's confirmed working
  @interval :timer.minutes(15)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    schedule_refresh(0)
    {:ok, nil}
  end

    @impl true
  def handle_info(:refresh, state) do
    Logger.info("Refreshing VEX events...")
    Scouter.Vex.sync(204, "California - Region 4")
    Logger.info("Refresh complete.")

    schedule_refresh(@interval)
    {:noreply, state}
  end

  defp schedule_refresh(delay) do
    Process.send_after(self(), :refresh, delay)
  end
end
