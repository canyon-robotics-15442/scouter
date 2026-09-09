defmodule Scouter.Repo.Migrations.AddSkuToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :sku, :string
    end
  end
end
