defmodule Scouter.Scouting.AnalysisTest do
  use ExUnit.Case, async: true

  alias Scouter.Scouting.Analysis

  test "team_strength computes wins*3 minus losses" do
    assert Analysis.team_strength(%{wins: 5, losses: 2}) == 13
  end

  test "rank_teams orders teams highest strength first" do
    teams = [
      %{name: "A", wins: 2, losses: 4},
      %{name: "B", wins: 8, losses: 1},
      %{name: "C", wins: 5, losses: 2}
    ]

    ranked = Analysis.rank_teams(teams)

    assert Enum.map(ranked, & &1.name) == ["B", "C", "A"]
  end

  test "event_difficulty labels a strong field as Hard" do
    teams = [%{wins: 10, losses: 0}, %{wins: 9, losses: 1}]
    assert Analysis.event_difficulty(teams) == "Hard"
  end

  test "event_difficulty labels a weak field as Easy" do
    teams = [%{wins: 1, losses: 5}, %{wins: 2, losses: 4}]
    assert Analysis.event_difficulty(teams) == "Easy"
  end
end