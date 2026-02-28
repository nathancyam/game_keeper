defmodule GameKeeper.Events.Message do
  @enforce_keys [:game_id, :messages, :from]
  defstruct [:game_id, :messages, :from, offset: nil, metadata: %{}]
end
