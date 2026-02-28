defmodule GameKeeper.Sports.Sport do
  @moduledoc """
  Behaviour that every sport module must implement.

  A sport module is responsible for declaring which event types it recognises
  and for validating individual events against its own ruleset.
  """

  @doc """
  Returns the list of atom event types supported by this sport.

  Example: `[:score, :foul, :timeout]`
  """
  @callback event_types() :: [atom()]

  @doc """
  Validates a raw event map against the sport's rules.

  Returns `{:ok, event}` on success or `{:error, reason}` on failure.
  The returned event may be the original map, a typed struct, or any
  normalised representation the sport module chooses.
  """
  @callback validate_event(type :: atom(), params :: map()) ::
              {:ok, term()} | {:error, term()}
end
