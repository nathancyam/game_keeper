defmodule GameKeeper.EventProcessing.Pipeline do
  @moduledoc """
  Broadway pipeline for ingesting game score events.

  ## Architecture

  Each processor calls `Games.log_scores/2`, which delegates to the
  `GameKeeper.Games.EventLog` GenServer for the given game via `GenServer.call/2`.

  ## Backpressure via EventLog

  `EventLog.log_scores/2` is a **synchronous, blocking** call. Each processor
  is held for the duration of the database transaction that persists the score
  events. Broadway will stop pulling from the producer once all processors are
  occupied, providing natural backpressure.

  Because each game has its own `EventLog` GenServer (looked up via
  `GameKeeper.GamesRegistry`), processors handling different games do not block
  each other. Contention only occurs when multiple messages target the same
  game, as they will queue behind that game's single GenServer mailbox.

  ## Message Flow

      Producer → transform/2 → handle_message/3 → EventLog.log_scores/2 → DB
                                                        ↑ blocks processor
  """

  use Broadway

  alias GameKeeper.EventProcessing
  alias GameKeeper.Games

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {EventProcessing.Producer, []},
        concurrency: 1,
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        default: [concurrency: 15]
      ]
    )
  end

  @impl Broadway
  def handle_message(_processor, %Broadway.Message{data: data} = b_msg, _context) do
    %EventProcessing.Message{game_id: game_id, messages: messages} = data
    {:ok, offset} = Games.log_scores(game_id, messages)
    Broadway.Message.update_data(b_msg, fn msg -> %{msg | offset: offset} end)
  end

  def transform(event, _opts) do
    %Broadway.Message{
      data: event,
      metadata: %{
        game_id: event.game_id
      },
      acknowledger: {EventProcessing.Producer, make_ref(), []}
    }
  end
end
