defmodule Scouter.Repo.Migrations.AddVexIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :vex_id, :integer
    end

    create unique_index(:events, [:vex_id])
  end
end
