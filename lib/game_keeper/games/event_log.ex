defmodule GameKeeper.Games.EventLog do
  use GenServer

  def start_event_log(game_id) when is_binary(game_id) do
    DynamicSupervisor.start_child(
      GameKeeper.Games.EventLogSupervisor,
      {__MODULE__, [name: via_tuple(game_id)]}
    )
  end

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Log a basketball score event. Blocks the caller until the event is recorded,
  providing backpressure when the log is under load.

  Points must be 1, 2, or 3.
  """
  def log_scores(game_id, scores) when is_binary(game_id) and is_list(scores) do
    GenServer.call(via_tuple(game_id), {:log_scores, scores})
  end

  @impl GenServer
  def init(_opts) do
    # State: %{game_id => [events]} — events stored newest-first, reversed on read
    {:ok, %{events: [], offset: 0}}
  end

  @impl GenServer
  def handle_call({:log_scores, score_events}, _from, state) do
    state =
      state
      |> Map.update(:events, score_events, &(score_events ++ &1))
      |> Map.update(:offset, length(score_events), &(&1 + length(score_events)))

    {:reply, {:ok, state.offset}, state}
  end

  defp via_tuple(game_id) when is_binary(game_id) do
    {:via, Registry, {GameKeeper.GamesRegistry, game_id}}
  end
end
