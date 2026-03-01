defmodule GameKeeper.Sports.Basketball do
  @moduledoc """
  Sport implementation for basketball.

  Defines the valid event types and validation rules for basketball games.
  """

  @behaviour GameKeeper.Sports.Sport

  alias GameKeeper.Sports.Basketball.ScoreEvent
  alias GameKeeper.Sports.Basketball.Team
  alias GameKeeper.Sports.Sport

  @valid_points [1, 2, 3]

  @impl Sport
  def event_types, do: [:score]

  @impl Sport
  def validate_event(:score, %{points: points, team: %Team{} = team, occurred_at: occurred_at})
      when points in @valid_points do
    {:ok, %ScoreEvent{points: points, team: team, occurred_at: occurred_at}}
  end

  def validate_event(:score, %{points: points}) when points not in @valid_points do
    {:error, {:invalid_points, points}}
  end

  def validate_event(:score, params) do
    missing = [:points, :team, :occurred_at] -- Map.keys(params)
    {:error, {:missing_fields, missing}}
  end

  def validate_event(type, _params) do
    {:error, {:unknown_event_type, type}}
  end
end
