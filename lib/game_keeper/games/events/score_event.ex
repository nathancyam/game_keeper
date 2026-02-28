defmodule GameKeeper.Games.ScoreEvent do
  @enforce_keys [:points, :team, :occurred_at]
  defstruct [:points, :team, :occurred_at]
end
