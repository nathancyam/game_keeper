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

  alias GameKeeper.Basketball.FoulEvent
  alias GameKeeper.Basketball.ScoreEvent
  alias GameKeeper.Basketball.Team
  alias GameKeeper.Basketball.TurnoverEvent
  alias GameKeeper.EventProcessing
  alias GameKeeper.Games

  # 2-pointers most common, 3-pointers second, free throws least common
  @point_weights [1, 2, 2, 2, 3, 3]
  # personal/shooting most common, technical very rare
  @foul_weights [:personal, :personal, :personal, :shooting, :shooting, :offensive, :loose_ball, :intentional, :technical]
  @plays_per_period 18..28
  @default_periods 4

  def simulate_many(count, prefix) when is_integer(count) and is_binary(prefix) do
    tasks =
      for _ <- 1..count do
        Task.async(fn ->
          simulate("#{prefix} #{random_name()}")
        end)
      end

    Task.await_many(tasks, :infinity)
  end

  @doc """
  Simulates a full game for `game_id`, logging each scoring play individually
  as it occurs.

  Returns `{:ok, %{home: integer, away: integer}}` with the final score.

  ## Options

    * `:periods` - number of periods to simulate (default: #{@default_periods})

  """
  @spec simulate(String.t()) :: {:ok, %{home: non_neg_integer(), away: non_neg_integer()}}
  @spec simulate(String.t(), [GameKeeper.Schemas.GameActor.t()], Keyword.t()) ::
          {:ok, %{home: non_neg_integer(), away: non_neg_integer()}}
  def simulate(name) do
    config = %GameKeeper.Sports.GameConfiguration{
      players: [
        %{
          name: random_name()
        },
        %{
          name: random_name()
        },
        %{
          name: random_name()
        }
      ]
    }

    {:ok, game, actors} = Games.create_game(:basketball, name, config)
    simulate(game.id, actors)
  end

  def simulate(game_id, actors, opts \\ []) do
    home_team = %Team{id: Ecto.UUID.generate(), name: "Home"}
    away_team = %Team{id: Ecto.UUID.generate(), name: "Away"}

    {:ok, _pid} = EventProcessing.start_event_log(game_id)

    periods = Keyword.get(opts, :periods, @default_periods)
    teams = [home_team, away_team]

    then = DateTime.add(DateTime.utc_now(), -4, :hour)

    {plays, _} =
      for _period <- 1..periods, reduce: {[], then} do
        {events, time} ->
          new_events = generate_period(teams, actors, time)
          {events ++ new_events, new_events |> List.last() |> Map.get(:occurred_at)}
      end

    score =
      plays
      |> List.flatten()
      |> Enum.reduce(%{home: 0, away: 0}, fn event, score ->
        {:ok, _offset} = Games.log_events(game_id, [event])

        case event do
          %ScoreEvent{} ->
            key = if event.team.id == home_team.id, do: :home, else: :away
            Map.update!(score, key, &(&1 + event.points))

          _ ->
            score
        end
      end)

    {:ok, score}
  end

  defp generate_period(teams, actors, start_time) do
    plays = Enum.random(@plays_per_period)

    {events, _time} =
      Enum.reduce(1..plays, {[], start_time}, fn _, {acc, time} ->
        random_actor_id = actors |> Enum.random() |> Map.get(:id)

        d20 = Enum.random(1..20)

        event =
          cond do
            d20 in 1..5 ->
              %FoulEvent{
                foul_type: Enum.random(@foul_weights),
                actor_id: random_actor_id,
                occurred_at: time
              }

            d20 in 6..9 ->
              %TurnoverEvent{
                cause: :travel,
                actor_id: random_actor_id,
                occurred_at: time
              }

            true ->
              %ScoreEvent{
                points: Enum.random(@point_weights),
                team: Enum.random(teams),
                actor_id: random_actor_id,
                occurred_at: time
              }
          end

        next_time = DateTime.add(time, Enum.random(10..45), :second)
        {[event | acc], next_time}
      end)

    Enum.reverse(events)
  end

  @first_names ~w(James Kevin Anthony Chris Paul Dwyane Carmelo Kyrie Stephen Russell)
  @last_names ~w(Johnson Williams Brown Davis Miller Wilson Moore Taylor Anderson Thomas)

  defp random_name, do: "#{Enum.random(@first_names)} #{Enum.random(@last_names)}"
end
