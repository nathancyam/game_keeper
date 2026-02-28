defmodule GameKeeper.Schemas.GameEventLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_event_logs" do
    field :type, :string
    field :value, :string
    field :metadata, :map
    field :occurred_at, :utc_datetime_usec

    belongs_to :game, GameKeeper.Schemas.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_event_log, attrs) do
    game_event_log
    |> cast(attrs, [:type, :value, :metadata, :occurred_at])
    |> validate_required([:type, :value, :occured_at])
  end
end
