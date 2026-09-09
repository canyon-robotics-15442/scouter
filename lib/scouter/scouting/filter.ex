defmodule Scouter.Scouting.Filter do
  def relevant_events(events, watched_team_numbers) do
    Enum.filter(events, fn event ->
      event.region == "California" or
        Enum.any?(event.team_numbers, &(&1 in watched_team_numbers))
    end)
  end
end
