defmodule GameKeeper.Simulators do
  @moduledoc """
  Entry point for game simulators.

  Each sport has its own simulator module under this namespace.
  """

  use Boundary, deps: [GameKeeper.Basketball, GameKeeper.EventProcessing, GameKeeper.Games]
end
