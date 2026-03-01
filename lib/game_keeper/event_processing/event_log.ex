defmodule GameKeeper.EventProcessing.EventLog do
  @moduledoc false
  use GenServer

  alias GameKeeper.EventProcessing
  alias GameKeeper.Repo

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    {:via, Registry, {GameKeeper.GamesRegistry, game_id}} = name
    GenServer.start_link(__MODULE__, Keyword.put(opts, :game_id, game_id), name: name)
  end

  @impl GenServer
  def init(opts) do
    game = opts[:game]
    events = EventProcessing.get_event_log(game)

    last_offset = events |> hd() |> Map.get(:offset)

    {:ok, %{game: game, sport: opts[:sport], events: events, offset: last_offset}}
  end

  @impl GenServer
  def handle_call({:log_scores, score_events}, _from, state) do
    start_metadata = %{game_id: state.game.id, pid: self()}

    state =
      :telemetry.span([:game_keeper, :event_log, :log_scores], start_metadata, fn ->
        state = Map.update(state, :events, score_events, &(score_events ++ &1))

        {:ok, game} =
          Repo.transact(fn ->
            %{game: game, processed_events: processed_events} = process_events(score_events, state)

            {_, _persisted_events} =
              Repo.insert_all(GameKeeper.Schemas.GameEventLog, processed_events,
                returning: true,
                placeholders: %{inserted_at: DateTime.utc_now(:second)}
              )

            {:ok, game}
          end)

        offset = state.offset + length(score_events)

        {%{state | game: game, offset: offset}, Map.put(start_metadata, :offset, offset)}
      end)

    {:reply, {:ok, state.offset}, state}
  end

  defp process_events(score_events, state) when is_list(score_events) do
    score_events_with_offsets = Enum.with_index(score_events, state.offset + 1)

    initial_acc = %{
      processed_events: [],
      game: state.game
    }

    for {%event_type{} = event, offset} <- score_events_with_offsets, reduce: initial_acc do
      acc ->
        {:ok, game} = state.sport.process_event(event, acc.game)

        known_props = %{
          offset: offset,
          inserted_at: {:placeholder, :inserted_at},
          module: to_string(event_type),
          game_id: state.game.id
        }

        props = Map.merge(event_type.dump(event), known_props)

        acc
        |> Map.put(:game, game)
        |> Map.update!(:processed_events, &[props | &1])
    end
  end
end
