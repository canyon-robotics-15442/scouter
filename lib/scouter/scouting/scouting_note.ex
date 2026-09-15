defmodule Scouter.Scouting.ScoutingNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scouting_notes" do
    belongs_to :team, Scouter.Scouting.Team
    field :author_email, :string
    field :body, :string

    timestamps()
  end

  def changeset(scouting_note, attrs) do
    scouting_note
    |> cast(attrs, [:team_id, :author_email, :body])
    |> validate_required([:team_id, :author_email, :body])
  end
end
