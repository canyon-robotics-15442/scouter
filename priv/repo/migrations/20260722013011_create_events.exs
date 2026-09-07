defmodule Scouter.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :date, :date
      add :region, :string

      timestamps()
    end
  end
end