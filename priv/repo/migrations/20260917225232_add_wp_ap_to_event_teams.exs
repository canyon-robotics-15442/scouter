defmodule Scouter.Repo.Migrations.AddWpApToEventTeams do
  use Ecto.Migration

  def change do
    alter table(:event_teams) do
      add :win_points, :integer
      add :autonomous_points, :integer
    end
  end
end
