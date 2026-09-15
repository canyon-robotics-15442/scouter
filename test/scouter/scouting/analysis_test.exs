defmodule Scouter.Scouting.AnalysisTest do
  use ExUnit.Case, async: true

  alias Scouter.Scouting.Analysis

  test "team_strength computes wins*3 minus losses" do
    assert Analysis.team_strength(%{wins: 5, losses: 2}) == 13
  end

  test "team_strength adds ties to the record score" do
    assert Analysis.team_strength(%{wins: 5, losses: 2, ties: 1}) == 14
  end

  test "team_strength folds in combined driver + programming skills, scaled down by 10" do
    assert Analysis.team_strength(%{wins: 5, losses: 2, driver_skills: 70, programming_skills: 65}) ==
             13 + 13.5
  end

  test "team_strength works with only skills data, no record yet" do
    assert Analysis.team_strength(%{driver_skills: 40, programming_skills: 30}) == 7.0
  end

  test "team_strength works with only record data, no skills yet" do
    assert Analysis.team_strength(%{wins: 3, losses: 1}) == 8
  end

  test "a large enough combined skills gap outranks a slightly better win/loss record" do
    strong_skills_weaker_record = %{wins: 4, losses: 2, driver_skills: 118, programming_skills: 88}
    weak_skills_better_record = %{wins: 5, losses: 1, driver_skills: 18, programming_skills: 88}

    ranked = Analysis.rank_teams([weak_skills_better_record, strong_skills_weaker_record])

    assert ranked == [strong_skills_weaker_record, weak_skills_better_record]
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

  test "decay_weight is 1.0 for an event happening today" do
    today = ~D[2026-09-14]
    assert Analysis.decay_weight(today, today) == 1.0
  end

  test "decay_weight is 0.5 exactly two months (60 days) after the event" do
    today = ~D[2026-09-14]
    two_months_ago = Date.add(today, -60)
    assert_in_delta Analysis.decay_weight(two_months_ago, today), 0.5, 0.0001
  end

  test "decay_weight keeps dropping the further back an event was" do
    today = ~D[2026-09-14]
    one_month_ago = Date.add(today, -30)
    four_months_ago = Date.add(today, -120)

    assert Analysis.decay_weight(one_month_ago, today) > Analysis.decay_weight(four_months_ago, today)
  end

  test "recency_weighted_strength returns 0 with no results yet" do
    assert Analysis.recency_weighted_strength([]) == 0
  end

  test "recency_weighted_strength matches team_strength for a single recent event" do
    today = ~D[2026-09-14]
    entries = [%{wins: 5, losses: 2, date: today}]

    assert Analysis.recency_weighted_strength(entries, today) == Analysis.team_strength(hd(entries))
  end

  test "recency_weighted_strength pulls the average toward the more recent event" do
    today = ~D[2026-09-14]

    entries = [
      %{wins: 10, losses: 0, date: today},
      %{wins: 0, losses: 10, date: Date.add(today, -120)}
    ]

    weighted = Analysis.recency_weighted_strength(entries, today)
    plain_average = (Analysis.team_strength(Enum.at(entries, 0)) + Analysis.team_strength(Enum.at(entries, 1))) / 2

    assert weighted > plain_average
  end
end
