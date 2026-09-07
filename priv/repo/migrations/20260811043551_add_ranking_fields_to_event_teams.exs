defmodule Scouter.Repo.Migrations.AddRankingFieldsToEventTeams do
  use Ecto.Migration

  def change do
    alter table(:event_teams) do
      add :wins, :integer
      add :losses, :integer
      add :ties, :integer
      add :rank, :integer
    end
  end
end
