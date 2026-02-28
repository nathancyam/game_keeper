defmodule GameKeeper.Games do
  use Boundary

  alias GameKeeper.Games.EventLog

  defdelegate start_event_log(game_id), to: EventLog

  defdelegate log_scores(game_id, events), to: EventLog
end
