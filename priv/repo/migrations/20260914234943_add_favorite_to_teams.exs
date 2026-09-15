defmodule Scouter.Repo.Migrations.AddFavoriteToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :favorite, :boolean, default: false, null: false
    end
  end
end
