defmodule Scouter.Scouting.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :vex_id, :integer
    field :number, :string
    field :name, :string
    field :organization, :string
    field :favorite, :boolean, default: false

    many_to_many :events, Scouter.Scouting.Event, join_through: Scouter.Scouting.EventTeam

    timestamps()
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:vex_id, :number, :name, :organization])
    |> validate_required([:vex_id, :number, :name])
  end

  def favorite_changeset(team, attrs) do
    cast(team, attrs, [:favorite])
  end
end
