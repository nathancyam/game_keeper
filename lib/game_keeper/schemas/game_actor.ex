defmodule GameKeeper.Schemas.GameActor do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_actors" do
    field :name, :string
    field :type, Ecto.Enum, values: [:player, :coach, :volunteer]

    has_many :events, GameKeeper.Schemas.GameEventLog,
      preload_order: [asc: :offset],
      foreign_key: :actor_id

    belongs_to :game, GameKeeper.Schemas.Game
    belongs_to :team, GameKeeper.Schemas.GameTeam

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_actor, attrs) do
    game_actor
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
  end
end
