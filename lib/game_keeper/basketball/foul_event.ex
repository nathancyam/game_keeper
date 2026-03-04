defmodule GameKeeper.Basketball.FoulEvent do
  @moduledoc """
  Represents a foul in a basketball game.

  Fouls can be committed by an individual actor (player or coach) or assessed
  against a team as a whole. The `foul_type` distinguishes the nature of the
  infraction.

  ## Foul types

    * `:personal` - standard player-to-player contact foul
    * `:shooting` - foul committed against a player in the act of shooting
    * `:offensive` - foul committed by the ball-handler (e.g. a charge)
    * `:loose_ball` - foul during a scramble for a loose ball
    * `:intentional` - deliberate foul, typically to stop the clock
    * `:flagrant_1` - unnecessary excessive contact; player remains in game
    * `:flagrant_2` - severe excessive contact; player is ejected
    * `:technical` - unsportsmanlike conduct assessed to a player, coach, or bench

  """

  @behaviour GameKeeper.Sports.EventType

  @type foul_type ::
          :personal
          | :shooting
          | :offensive
          | :loose_ball
          | :intentional
          | :flagrant_1
          | :flagrant_2
          | :technical

  @type t :: %__MODULE__{
          foul_type: foul_type(),
          actor_id: Ecto.UUID.t() | nil,
          team_id: Ecto.UUID.t() | nil,
          occurred_at: DateTime.t(),
          offset: integer() | nil,
          inserted_at: DateTime.t() | nil
        }

  @enforce_keys [:foul_type, :occurred_at]
  defstruct [:foul_type, :occurred_at, actor_id: nil, team_id: nil, offset: nil, inserted_at: nil]

  def dump(%__MODULE__{} = foul) do
    %{
      type: "foul",
      value: to_string(foul.foul_type),
      actor_id: foul.actor_id,
      team_id: foul.team_id,
      occurred_at: foul.occurred_at
    }
  end

  def load(%GameKeeper.Schemas.GameEventLog{} = log_event, _game) do
    %__MODULE__{
      foul_type: String.to_existing_atom(log_event.value),
      actor_id: log_event.actor_id,
      team_id: log_event.team_id,
      occurred_at: log_event.occurred_at,
      offset: log_event.offset,
      inserted_at: log_event.inserted_at
    }
  end
end
