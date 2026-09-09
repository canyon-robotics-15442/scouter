defmodule Scouter.Scouting.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :vex_id, :integer
    field :sku, :string
    field :name, :string
    field :date, :date
    field :region, :string

    many_to_many :teams, Scouter.Scouting.Team, join_through: Scouter.Scouting.EventTeam

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:vex_id, :sku, :name, :date, :region])
    |> validate_required([:vex_id, :sku, :name, :date])
  end
end
