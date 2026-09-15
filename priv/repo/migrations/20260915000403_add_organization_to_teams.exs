defmodule Scouter.Repo.Migrations.AddOrganizationToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :organization, :string
    end
  end
end
