defmodule GameKeeper.EventProcessing do
  @moduledoc false
  use Boundary, deps: [GameKeeper.Games, GameKeeper.Schemas, GameKeeper.Repo]

  import Ecto.Query

  alias GameKeeper.EventProcessing.EventLog
  alias GameKeeper.EventProcessing.Pipeline
  alias GameKeeper.Games
  alias GameKeeper.Repo
  alias GameKeeper.Schemas.Game
  alias GameKeeper.Schemas.GameEventLog

  def start_event_log(game_id) when is_binary(game_id) do
    {game, sport_module} = Games.get_game_for_event_log!(game_id)

    DynamicSupervisor.start_child(
      GameKeeper.Games.EventLogSupervisor,
      {EventLog, [name: Games.via_event_log_tuple(game_id), game: game, sport: sport_module]}
    )
  end

  def push_and_ack_events(game_id, events) when is_binary(game_id) and is_list(events) do
    producer =
      Pipeline
      |> Broadway.producer_names()
      |> Enum.random()

    GenStage.call(producer, {:push_events, game_id, events})
  end

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
