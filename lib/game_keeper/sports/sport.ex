defmodule GameKeeper.Sports.Sport do
  @moduledoc """
  Behaviour that every sport module must implement.

  A sport module is responsible for declaring which event types it recognises
  and for validating individual events against its own ruleset.
  """

  alias GameKeeper.Schemas.Game

  @doc """
  Returns the list of atom event types supported by this sport.

  Example: `[:score, :foul, :timeout]`
  """
  @callback event_types() :: [atom()]

  @callback process_event(sport_event :: term(), game :: Game.t()) ::
              {:ok, Game.t()} | {:error, any()}
end
