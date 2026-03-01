defmodule GameKeeper.Events.Producer do
  @moduledoc false
  @behaviour Broadway.Acknowledger

  use GenStage

  alias GameKeeper.Events.Message

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def push_and_ack_events(game_id, events) when is_binary(game_id) and is_list(events) do
    [producer] = Broadway.producer_names(GameKeeper.Events.Pipeline)
    GenStage.call(producer, {:push_events, game_id, events})
  end

  @impl GenStage
  def init(config) do
    {:producer, config}
  end

  @impl GenStage
  def handle_call({:push_events, game_id, events}, from, state) do
    message = %Message{
      game_id: game_id,
      messages: events,
      from: from
    }

    {:noreply, [message], state}
  end

  @impl GenStage
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @impl Broadway.Acknowledger
  def ack(_ref, successful, failed) do
    Enum.each(successful, fn %{data: %{from: from, offset: offset} = _successful_msg} ->
      GenStage.reply(from, {:ok, offset})
    end)

    Enum.each(failed, fn %{data: %{from: from}} ->
      GenStage.reply(from, {:error, :failed})
    end)

    :ok
  end
end
