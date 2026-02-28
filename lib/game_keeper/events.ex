defmodule GameKeeper.Events do
  use Boundary, deps: [GameKeeper.Games]

  alias GameKeeper.Events.Pipeline

  def push_and_ack_events(game_id, events) when is_binary(game_id) and is_list(events) do
    producer =
      Pipeline
      |> Broadway.producer_names()
      |> Enum.random()

    GenStage.call(producer, {:push_events, game_id, events})
  end
end
