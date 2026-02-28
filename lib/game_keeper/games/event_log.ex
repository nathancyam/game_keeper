defmodule GameKeeper.Games.EventLog do
  use GenServer

  alias GameKeeper.Games

  def start_event_log(game_id) when is_binary(game_id) do
    DynamicSupervisor.start_child(
      GameKeeper.Games.EventLogSupervisor,
      {__MODULE__, [name: via_tuple(game_id)]}
    )
  end

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    {:via, Registry, {GameKeeper.GamesRegistry, game_id}} = name
    GenServer.start_link(__MODULE__, Keyword.put(opts, :game_id, game_id), name: name)
  end

  @doc """
  Log a list of score events for a game. Blocks the caller until the events are
  recorded, providing backpressure when the log is under load.
  """
  def log_scores(game_id, scores) when is_binary(game_id) and is_list(scores) do
    GenServer.call(via_tuple(game_id), {:log_scores, scores})
  end

  @impl GenServer
  def init(opts) do
    # State: %{game_id => [events]} — events stored newest-first, reversed on read
    {:ok, %{game_id: opts[:game_id], events: [], offset: 0}}
  end

  @impl GenServer
  def handle_call({:log_scores, score_events}, _from, state) do
    start_metadata = %{game_id: state.game_id, pid: self()}

    state =
      :telemetry.span([:game_keeper, :event_log, :log_scores], start_metadata, fn ->
        state =
          state
          |> Map.update(:events, score_events, &(score_events ++ &1))
          |> Map.update(:offset, length(score_events), &(&1 + length(score_events)))

        GameKeeper.Repo.transact(fn ->
          for event <- score_events do
            Games.insert_score_event(state.game_id, event)
          end

          {:ok, []}
        end)

        {state, Map.put(start_metadata, :offset, state.offset)}
      end)

    {:reply, {:ok, state.offset}, state}
  end

  defp via_tuple(game_id) when is_binary(game_id) do
    {:via, Registry, {GameKeeper.GamesRegistry, game_id}}
  end
end
