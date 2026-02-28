defmodule GameKeeper.Events.Pipeline do
  use Broadway

  alias GameKeeper.Events
  alias GameKeeper.Games

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {GameKeeper.Events.Producer, []},
        concurrency: 1,
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        default: [concurrency: 15]
      ]
    )
  end

  @impl Broadway
  def handle_message(
        _processor,
        %Broadway.Message{data: data} = b_msg,
        _context
      ) do
    %Events.Message{game_id: game_id, messages: messages} = data
    {:ok, offset} = Games.log_scores(game_id, messages)
    Broadway.Message.update_data(b_msg, fn msg -> %{msg | offset: offset} end)
  end

  def transform(event, _opts) do
    %Broadway.Message{
      data: event,
      metadata: %{
        game_id: event.game_id
      },
      acknowledger: {GameKeeper.Events.Producer, make_ref(), []}
    }
  end
end
