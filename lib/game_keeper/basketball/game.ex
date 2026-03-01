defmodule GameKeeper.Basketball.Game do
  @moduledoc """
  Represents the state of a basketball game.
  """

  alias GameKeeper.Basketball.Team

  @enforce_keys [:id, :home_team, :away_team]
  defstruct [:id, :home_team, :away_team, period: 1, status: :scheduled]

  @type status :: :scheduled | :in_progress | :finished

  @type t :: %__MODULE__{
          id: term(),
          home_team: Team.t(),
          away_team: Team.t(),
          period: pos_integer(),
          status: status()
        }
end
