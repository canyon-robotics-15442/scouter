defmodule Scouter.Scouting.Analysis do
  @decay_half_life_days 60

  def decay_weight(event_date, today \\ Date.utc_today()) do
    days_ago = Date.diff(today, event_date)
    :math.pow(0.5, days_ago / @decay_half_life_days)
  end

  def recency_weighted_strength(entries, today \\ Date.utc_today())
  def recency_weighted_strength([], _today), do: 0

  def recency_weighted_strength(entries, today) do
    weighted = Enum.map(entries, &{team_strength(&1), decay_weight(&1.date, today)})
    total_weight = weighted |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    weighted
    |> Enum.map(fn {strength, weight} -> strength * weight end)
    |> Enum.sum()
    |> Kernel./(total_weight)
  end

  def team_strength(stats) do
    record_score(stats) + skills_score(stats)
  end

  defp record_score(stats) do
    wins = Map.get(stats, :wins) || 0
    losses = Map.get(stats, :losses) || 0
    ties = Map.get(stats, :ties) || 0
    wins * 3 + ties - losses
  end

  defp skills_score(stats) do
    driver = Map.get(stats, :driver_skills) || 0
    programming = Map.get(stats, :programming_skills) || 0
    (driver + programming) / 10
  end

  def rank_teams(team_stats) do
    Enum.sort_by(team_stats, &team_strength/1, :desc)
  end

  def event_difficulty(team_stats) do
    avg =
      team_stats
      |> Enum.map(&team_strength/1)
      |> Enum.sum()
      |> Kernel./(length(team_stats))

    cond do
      avg >= 15 -> "Hard"
      avg >= 8 -> "Medium"
      true -> "Easy"
    end
  end
end
