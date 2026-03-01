defmodule GameKeeper.Basketball.ScoreEvent do
  @moduledoc """
  Represents a single scoring play in a basketball game.
  """

  @behaviour GameKeeper.Sports.EventType

  @enforce_keys [:points, :team, :occurred_at]
  defstruct [:points, :team, :occurred_at, offset: nil, inserted_at: nil]

  @type t :: %__MODULE__{
          points: 1 | 2 | 3,
          team: GameKeeper.Basketball.Team.t(),
          occurred_at: DateTime.t()
        }

  def dump(%__MODULE__{} = score) do
    %{
      type: "score",
      value: to_string(score.points),
      occurred_at: score.occurred_at
    }
  end

  def load(%GameKeeper.Schemas.GameEventLog{} = log_event, _game) do
    %__MODULE__{
      points: String.to_integer(log_event.value),
      team: nil,
      occurred_at: log_event.occurred_at,
      offset: log_event.offset,
      inserted_at: log_event.inserted_at
    }
  end
end
