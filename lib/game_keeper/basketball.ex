defmodule GameKeeper.Basketball do
  @moduledoc """
  Sport implementation and public API for basketball.

  Implements the `GameKeeper.Sports.Sport` behaviour, defining the valid event
  types and validation rules specific to basketball.
  """

  @behaviour GameKeeper.Sports.Sport

  use Boundary, deps: [GameKeeper.Schemas, GameKeeper.Sports], exports: :all

  alias GameKeeper.Basketball.FoulEvent
  alias GameKeeper.Basketball.ScoreEvent
  alias GameKeeper.Basketball.TurnoverEvent
  alias GameKeeper.Schemas.Game
  alias GameKeeper.Sports.Sport

  @impl Sport
  def event_types, do: [:score]

  @impl Sport
  def process_event(%ScoreEvent{}, %Game{} = game) do
    {:ok, game}
  end

  def process_event(%FoulEvent{}, %Game{} = game) do
    {:ok, game}
  end

  def process_event(%TurnoverEvent{}, %Game{} = game) do
    {:ok, game}
  end
end
