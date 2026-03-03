defmodule GameKeeper.Games do
  @moduledoc """
  Context for game management.

  Handles creation of games and provides the interface for logging score events
  directly to a game's `EventLog` GenServer.
  """
  use Boundary,
    deps: [
      GameKeeper.Repo,
      GameKeeper.Schemas,
      GameKeeper.Sports,
      GameKeeper.Basketball
    ]

  alias Ecto.Changeset
  alias GameKeeper.Repo
  alias GameKeeper.Schemas.Game
  alias GameKeeper.Schemas.GameActor
  alias GameKeeper.Sports.GameConfiguration

  @doc """
  Creates a new game record for the given sport and name.

  Returns `{:ok, %Game{}, [%GameActor{}]}` on success or `{:error, changeset}` on validation
  failure.
  """
  def create_game(sport, name, %GameConfiguration{} = config) when is_atom(sport) and is_binary(name) do
    {:ok, {game, actors}} =
      Repo.transact(fn ->
        {:ok, game} =
          %Game{}
          |> Changeset.cast(%{sport: sport, name: name}, [:sport, :name])
          |> Changeset.validate_required([:sport, :name])
          |> Repo.insert()

        placeholders = %{timestamp: DateTime.utc_now(:second)}

        actors =
          Enum.flat_map([:players, :coaches, :volunteers], fn role ->
            config
            |> Map.get(role, [])
            |> Enum.map(fn actor ->
              %{
                game_id: game.id,
                type:
                  case role do
                    :players -> :player
                    :coaches -> :coach
                    :volunteers -> :volunteer
                  end,
                name: actor.name,
                inserted_at: {:placeholder, :timestamp},
                updated_at: {:placeholder, :timestamp}
              }
            end)
          end)

        {_, actors} = Repo.insert_all(GameActor, actors, placeholders: placeholders, returning: true)
        {:ok, {game, actors}}
      end)

    {:ok, game, actors}
  end

  @doc """
  Log a list of score events for a game. Blocks the caller until the events are
  recorded, providing backpressure when the log is under load.
  """
  def log_events(game_id, messages) when is_binary(game_id) and is_list(messages) do
    GenServer.call(via_event_log_tuple(game_id), {:log_events, messages})
  end

  def get_game_for_event_log!(game_id) when is_binary(game_id) do
    %Game{} = game = Repo.get_by!(Game, id: game_id)

    with {:ok, sport_module} <- GameKeeper.Sports.fetch_sport(game.sport) do
      {game, sport_module}
    end
  end

  def via_event_log_tuple(game_id) when is_binary(game_id) do
    {:via, Registry, {GameKeeper.GamesRegistry, game_id}}
  end
end
