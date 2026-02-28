defmodule GameKeeper.Games do
  use Boundary

  def start_event_log(game_id) when is_binary(game_id) do
    GameKeeper.Games.EventLog.start_link(game_id)
  end

  defdelegate log_scores(game_id, events), to: GameKeeper.Games.EventLog
end
