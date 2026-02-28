defmodule GameKeeper.Events do
  use Boundary, deps: [GameKeeper.Games]

  alias GameKeeper.Events.Pipeline

  def push_and_ack_events(game_id, events)
      when is_binary(game_id) and is_list(events) do
    [producer] = Broadway.producer_names(Pipeline)
    GenStage.call(producer, {:push_events, game_id, events})
  end
end
