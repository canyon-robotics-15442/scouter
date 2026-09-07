defmodule Scouter.Repo.Migrations.CreateEventTeams do
  use Ecto.Migration

  def change do
    create table(:event_teams) do
      add :event_id, references(:events, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:event_teams, [:event_id, :team_id])
  end
end