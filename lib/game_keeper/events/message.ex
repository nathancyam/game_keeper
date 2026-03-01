defmodule GameKeeper.Events.Message do
  @moduledoc false
  @enforce_keys [:game_id, :messages, :from]
  defstruct [:game_id, :messages, :from, offset: nil, metadata: %{}]
end
