defmodule GameKeeper.Sports.Basketball.ScoreEvent do
  @moduledoc """
  Represents a single scoring play in a basketball game.
  """

  @enforce_keys [:points, :team, :occurred_at]
  defstruct [:points, :team, :occurred_at]

  @type t :: %__MODULE__{
          points: 1 | 2 | 3,
          team: GameKeeper.Sports.Basketball.Team.t(),
          occurred_at: DateTime.t()
        }
end
