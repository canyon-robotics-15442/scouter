defmodule Scouter.Repo.Migrations.AddSpToEventTeams do
  use Ecto.Migration

  def change do
    alter table(:event_teams) do
      add :strength_of_schedule_points, :integer
    end
  end
end
