defmodule Scouter.Scouting.EventTeam do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_teams" do
    belongs_to :event, Scouter.Scouting.Event
    belongs_to :team, Scouter.Scouting.Team
    field :wins, :integer
    field :losses, :integer
    field :ties, :integer
    field :rank, :integer

    timestamps()
  end

  def ranking_changeset(event_team, attrs) do
    cast(event_team, attrs, [:wins, :losses, :ties, :rank])
  end
end
