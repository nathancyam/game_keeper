defmodule GameKeeper.EventProcessing do
  @moduledoc false
  use Boundary, deps: [GameKeeper.Games, GameKeeper.Repo]

  alias GameKeeper.EventProcessing.EventLog
  alias GameKeeper.EventProcessing.Pipeline
  alias GameKeeper.Games

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
end
