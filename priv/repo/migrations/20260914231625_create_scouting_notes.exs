defmodule Scouter.Repo.Migrations.CreateScoutingNotes do
  use Ecto.Migration

  def change do
    create table(:scouting_notes) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :author_email, :string, null: false
      add :body, :text, null: false

      timestamps()
    end

    create index(:scouting_notes, [:team_id])
  end
end
