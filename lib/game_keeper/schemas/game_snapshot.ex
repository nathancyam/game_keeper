defmodule GameKeeper.Schemas.GameSnapshot do
  @moduledoc """
  Persists a point-in-time checkpoint of a game's state.

  A snapshot captures the full game state at a given `offset` in the event log.
  Rather than replaying all events from the beginning to derive current state,
  consumers can load the nearest snapshot and only replay the delta of events
  that follow it.

  The `module` field identifies the Elixir module whose struct is serialised into
  the `snapshot` map — for example, a basketball game would use
  `GameKeeper.Basketball.Game` and store its fields as JSON. That same module is
  responsible for deserialising the map back into the appropriate struct.

  Snapshots are immutable once written; they represent a historical record of
  state at a specific point in the event stream.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_snapshots" do
    field :offset, :integer

    field :module, :string
    field :snapshot, :map

    belongs_to :game, GameKeeper.Schemas.Game

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc false
  def changeset(game_snapshot, attrs) do
    game_snapshot
    |> cast(attrs, [:module, :offset, :snapshot])
    |> validate_required([:module, :offset])
  end
end
