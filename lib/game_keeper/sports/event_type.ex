defmodule GameKeeper.Sports.EventType do
  @moduledoc false
  alias GameKeeper.Schemas.GameEventLog

  @callback dump(sport_event :: struct()) :: GameEventLog.t()

  @callback load(event :: GameEventLog.t(), game :: GameKeeper.Schemas.Game.t()) :: any()
end
