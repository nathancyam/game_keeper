defmodule GameKeeper.Schemas.Game do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :name, :string
    field :sport, Ecto.Enum, values: [:basketball]

    has_many :events, GameKeeper.Schemas.GameEventLog, preload_order: [asc: :occured_at]
    has_many :actors, GameKeeper.Schemas.GameActor
    has_many :teams, GameKeeper.Schemas.GameTeam

    has_many :snapshots, GameKeeper.Schemas.GameSnapshot

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :sport])
    |> validate_required([:name, :sport])
  end
end
