defmodule GameKeeper.Simulators.Basketball do
  @moduledoc """
  Simulates a basketball game by generating random scoring plays and logging
  them through the normal `Games.log_scores/2` pipeline, one play at a time.

  Point values are weighted to reflect realistic shot distributions:
  2-pointers are most common, followed by 3-pointers, then free throws (1 point).

  ## Example

      home = %GameKeeper.Basketball.Team{id: "home", name: "Home Team"}
      away = %GameKeeper.Basketball.Team{id: "away", name: "Away Team"}

      {:ok, result} = GameKeeper.Simulators.Basketball.simulate(game_id, home, away)
      # => {:ok, %{home: 98, away: 104}}

  """

  alias GameKeeper.Basketball.ScoreEvent
  alias GameKeeper.Basketball.Team
  alias GameKeeper.EventProcessing
  alias GameKeeper.Games

  # 2-pointers most common, 3-pointers second, free throws least common
  @point_weights [1, 2, 2, 2, 3, 3]
  @plays_per_period 18..28
  @default_periods 4

  @doc """
  Simulates a full game for `game_id`, logging each scoring play individually
  as it occurs.

  Returns `{:ok, %{home: integer, away: integer}}` with the final score.

  ## Options

    * `:periods` - number of periods to simulate (default: #{@default_periods})

  """
  @spec simulate(String.t(), Team.t(), Team.t(), keyword()) ::
          {:ok, %{home: non_neg_integer(), away: non_neg_integer()}}
  def simulate(game_id, %Team{} = home_team, %Team{} = away_team, opts \\ []) do
    {:ok, _pid} = EventProcessing.start_event_log(game_id)

    periods = Keyword.get(opts, :periods, @default_periods)
    teams = [home_team, away_team]
    plays = for _period <- 1..periods, do: generate_period(teams)

    score =
      plays
      |> List.flatten()
      |> Enum.reduce(%{home: 0, away: 0}, fn event, score ->
        {:ok, _offset} = Games.log_events(game_id, [event])

        key = if event.team.id == home_team.id, do: :home, else: :away
        Map.update!(score, key, &(&1 + event.points))
      end)

    {:ok, score}
  end

  defp generate_period(teams) do
    plays = Enum.random(@plays_per_period)

    {events, _time} =
      Enum.reduce(1..plays, {[], DateTime.utc_now()}, fn _, {acc, time} ->
        event = %ScoreEvent{
          points: Enum.random(@point_weights),
          team: Enum.random(teams),
          occurred_at: time
        }

        {[event | acc], DateTime.add(time, Enum.random(10..45), :second)}
      end)

    Enum.reverse(events)
  end
end
