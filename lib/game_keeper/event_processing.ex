defmodule GameKeeper.EventProcessing do
  @moduledoc """
  Public API for game event processing.

  This module is the main entry point for starting per-game event logs,
  pushing events through the Broadway pipeline, and reading back persisted
  events for a game.

  ## Event log lifecycle

  Before events can be logged for a game, an `EventLog` GenServer must be
  started for it via `start_event_log/1`. The GenServer is registered under
  the game's ID in `GameKeeper.GamesRegistry` and supervised by
  `GameKeeper.Games.EventLogSupervisor`. On startup it restores its in-memory
  state from the database so the offset is consistent across restarts.

  ## Pushing events

  `push_and_ack_events/2` routes events through the Broadway pipeline
  (`EventProcessing.Pipeline`). It selects a producer at random for load
  distribution and blocks the caller until the pipeline has processed and
  acknowledged the batch, returning the resulting offset.

  ## Reading events

  `get_event_log/1` loads all persisted events for a game, ordered by offset
  descending, and deserialises each row back into its sport-specific struct via
  the `module` field stored on the record.
  """
  use Boundary, deps: [GameKeeper.Games, GameKeeper.Schemas, GameKeeper.Repo]

  import Ecto.Query

  alias GameKeeper.EventProcessing.EventLog
  alias GameKeeper.EventProcessing.Pipeline
  alias GameKeeper.Games
  alias GameKeeper.Repo
  alias GameKeeper.Schemas.Game
  alias GameKeeper.Schemas.GameEventLog

  @doc """
  Starts an `EventLog` GenServer for the given game.

  Looks up the game and its associated sport module, then starts a supervised
  GenServer registered under `game_id`. Returns `{:ok, pid}` on success or
  `{:error, {:already_started, pid}}` if an event log is already running for
  this game.
  """
  def start_event_log(game_id) when is_binary(game_id) do
    {game, sport_module} = Games.get_game_for_event_log!(game_id)

    DynamicSupervisor.start_child(
      GameKeeper.Games.EventLogSupervisor,
      {EventLog, [name: Games.via_event_log_tuple(game_id), game: game, sport: sport_module]}
    )
  end

  @doc """
  Pushes a list of events into the Broadway pipeline and blocks until they are
  acknowledged.

  A producer is chosen at random from the pipeline for load distribution.
  Returns `{:ok, offset}` once the events have been written to the event log.
  """
  def push_and_ack_events(game_id, events) when is_binary(game_id) and is_list(events) do
    producer =
      Pipeline
      |> Broadway.producer_names()
      |> Enum.random()

    GenStage.call(producer, {:push_events, game_id, events})
  end

  @doc """
  Returns all persisted events for a game, ordered by offset descending.

  Each database row is deserialised back into its sport-specific struct by
  calling the `load/2` callback on the module stored in the record's `module`
  field.
  """
  def get_event_log(%Game{} = game) do
    query =
      from el in Ecto.assoc(game, :events),
        order_by: {:desc, :offset}

    query
    |> Repo.all()
    |> Enum.map(fn %GameEventLog{module: raw_module} = event ->
      module = String.to_existing_atom(raw_module)
      module.load(event, game)
    end)
  end
end
