defmodule GameKeeper.Sports do
  @moduledoc """
  Public API for sport-specific logic.

  Dispatches to the appropriate sport module based on the sport string stored
  on a game (e.g. `"basketball"`). Each sport module implements the
  `GameKeeper.Sports.Sport` behaviour.
  """

  @sports %{
    "basketball" => GameKeeper.Sports.Basketball
  }

  @doc """
  Returns the list of valid event types for the given sport.

  Returns `{:error, :unknown_sport}` if the sport is not registered.
  """
  @spec event_types(String.t()) :: {:ok, [atom()]} | {:error, :unknown_sport}
  def event_types(sport) do
    with {:ok, mod} <- fetch_sport(sport) do
      {:ok, mod.event_types()}
    end
  end

  @doc """
  Validates an event against the rules for the given sport.

  Returns `{:ok, event}` or `{:error, reason}`.
  """
  @spec validate_event(String.t(), atom(), map()) ::
          {:ok, term()} | {:error, term()}
  def validate_event(sport, type, params) do
    with {:ok, mod} <- fetch_sport(sport) do
      mod.validate_event(type, params)
    end
  end

  defp fetch_sport(sport) do
    case Map.fetch(@sports, sport) do
      {:ok, mod} -> {:ok, mod}
      :error -> {:error, :unknown_sport}
    end
  end
end
