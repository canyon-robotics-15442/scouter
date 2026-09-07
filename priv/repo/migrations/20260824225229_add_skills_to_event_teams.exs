defmodule Scouter.Repo.Migrations.AddSkillsToEventTeams do
  use Ecto.Migration

  def change do
    alter table(:event_teams) do
      add :driver_skills, :integer
      add :programming_skills, :integer
    end
  end
end
