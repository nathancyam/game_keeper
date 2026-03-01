defmodule GameKeeper.Games.EventLogTest do
  use GameKeeperSupport.DataCase, async: false

  alias GameKeeper.Games
  alias GameKeeper.Games.EventLog
  alias GameKeeper.Sports.Basketball.ScoreEvent
  alias GameKeeper.Sports.Basketball.Team

  @team %Team{id: "team-a", name: "Team A"}

  defp score_event(points \\ 2) do
    %ScoreEvent{points: points, team: @team, occurred_at: DateTime.utc_now()}
  end

  setup do
    {:ok, game} = Games.create_game("basketball", "Test Game")

    pid =
      start_supervised!({EventLog, [name: {:via, Registry, {GameKeeper.GamesRegistry, game.id}}]})

    Ecto.Adapters.SQL.Sandbox.allow(GameKeeper.Repo, self(), pid)

    %{game: game}
  end

  test "registers under the game's id in the registry", %{game: game} do
    assert [{pid, _}] = Registry.lookup(GameKeeper.GamesRegistry, game.id)
    assert is_pid(pid)
  end

  test "log_scores/2 returns offset of 1 after a single event", %{game: game} do
    assert {:ok, 1} = EventLog.log_scores(game.id, [score_event()])
  end

  test "offset increments with successive calls", %{game: game} do
    assert {:ok, 1} = EventLog.log_scores(game.id, [score_event()])
    assert {:ok, 2} = EventLog.log_scores(game.id, [score_event()])
    assert {:ok, 3} = EventLog.log_scores(game.id, [score_event()])
  end

  test "offset advances by the number of events in a single call", %{game: game} do
    assert {:ok, 4} = EventLog.log_scores(game.id, List.duplicate(score_event(), 4))
  end

  test "offset accumulates correctly across mixed-size batches", %{game: game} do
    assert {:ok, 3} = EventLog.log_scores(game.id, List.duplicate(score_event(), 3))
    assert {:ok, 4} = EventLog.log_scores(game.id, [score_event()])
    assert {:ok, 7} = EventLog.log_scores(game.id, List.duplicate(score_event(), 3))
  end

  test "logging an empty list returns the current offset unchanged", %{game: game} do
    assert {:ok, 2} = EventLog.log_scores(game.id, List.duplicate(score_event(), 2))
    assert {:ok, 2} = EventLog.log_scores(game.id, [])
  end
end
