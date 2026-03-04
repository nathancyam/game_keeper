defmodule GameKeeper.Schemas.GameSnapshot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_snapshots" do
    field :module, :string
    field :offset, :integer
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
