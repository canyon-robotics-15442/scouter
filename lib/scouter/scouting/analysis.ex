defmodule Scouter.Scouting.Analysis do
  def team_strength(%{wins: w, losses: l}) do
    w * 3 - l
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