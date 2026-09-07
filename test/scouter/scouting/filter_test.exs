defmodule Scouter.Scouting.FilterTest do
  use ExUnit.Case, async: true

  alias Scouter.Scouting.Filter

  test "includes California events regardless of attending teams" do
    events = [%{name: "CA Event", region: "California", team_numbers: ["1111A"]}]

    assert Filter.relevant_events(events, ["9999A"]) == events
  end

  test "includes out-of-state events if a watched team is attending" do
    events = [%{name: "Texas Event", region: "Texas", team_numbers: ["9999A", "1111A"]}]

    assert Filter.relevant_events(events, ["9999A"]) == events
  end

  test "excludes out-of-state events with no watched teams" do
    events = [%{name: "Texas Event", region: "Texas", team_numbers: ["1111A"]}]

    assert Filter.relevant_events(events, ["9999A"]) == []
  end
end