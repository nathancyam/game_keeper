defmodule GameKeeper.Schemas.GameEventLog do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_event_logs" do
    field :type, :string
    field :value, :string
    field :metadata, :map
    field :occurred_at, :utc_datetime_usec
    field :offset, :integer

    field :module, :string

    belongs_to :game, GameKeeper.Schemas.Game
    belongs_to :actor, GameKeeper.Schemas.GameActor, foreign_key: :actor_id
    belongs_to :team, GameKeeper.Schemas.GameTeam

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(game_event_log, attrs) do
    game_event_log
    |> cast(attrs, [:type, :value, :metadata, :occurred_at])
    |> validate_required([:type, :value, :occured_at])
  end
end
