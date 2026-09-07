defmodule Scouter.Repo.Migrations.AddVexIdToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :vex_id, :integer
    end

    create unique_index(:teams, [:vex_id])
  end
end
