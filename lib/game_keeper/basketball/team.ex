defmodule GameKeeper.Basketball.Team do
  @moduledoc """
  Represents a team participating in a basketball game.
  """

  @type t :: %__MODULE__{
          id: term(),
          name: String.t()
        }

  @enforce_keys [:id, :name]
  defstruct [:id, :name]
end
