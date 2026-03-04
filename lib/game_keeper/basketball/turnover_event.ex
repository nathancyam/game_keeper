defmodule GameKeeper.Basketball.TurnoverEvent do
  @moduledoc """
  Represents a turnover in a basketball game.

  A turnover occurs when the offensive team loses possession without attempting
  a shot. The `cause` describes how the turnover happened.

  For stolen ball turnovers, the defending actor who made the steal is stored in
  `stolen_by_actor_id` and persisted via the `metadata` map.

  ## Causes

    * `:travel` - player took too many steps without dribbling
    * `:double_dribble` - player dribbled, stopped, then dribbled again
    * `:bad_pass` - errant pass that went out of bounds or off the intended receiver
    * `:stolen` - ball stripped or intercepted by a defender
    * `:out_of_bounds` - player stepped out or ball went out off their possession
    * `:shot_clock` - team failed to attempt a shot within the shot clock
    * `:offensive_foul` - charge called on the ball-handler

  """

  @behaviour GameKeeper.Sports.EventType

  @type cause ::
          :travel
          | :double_dribble
          | :bad_pass
          | :stolen
          | :out_of_bounds
          | :shot_clock
          | :offensive_foul

  @type t :: %__MODULE__{
          cause: cause(),
          actor_id: Ecto.UUID.t() | nil,
          stolen_by_actor_id: Ecto.UUID.t() | nil,
          occurred_at: DateTime.t(),
          offset: integer() | nil,
          inserted_at: DateTime.t() | nil
        }

  @enforce_keys [:cause, :occurred_at]
  defstruct [
    :cause,
    :occurred_at,
    actor_id: nil,
    stolen_by_actor_id: nil,
    offset: nil,
    inserted_at: nil
  ]

  def dump(%__MODULE__{} = turnover) do
    metadata =
      case turnover.stolen_by_actor_id do
        nil -> nil
        id -> %{"stolen_by" => id}
      end

    %{
      type: "turnover",
      value: to_string(turnover.cause),
      actor_id: turnover.actor_id,
      metadata: metadata,
      occurred_at: turnover.occurred_at
    }
  end

  def load(%GameKeeper.Schemas.GameEventLog{} = log_event, _game) do
    stolen_by = log_event.metadata && log_event.metadata["stolen_by"]

    %__MODULE__{
      cause: String.to_existing_atom(log_event.value),
      actor_id: log_event.actor_id,
      stolen_by_actor_id: stolen_by,
      occurred_at: log_event.occurred_at,
      offset: log_event.offset,
      inserted_at: log_event.inserted_at
    }
  end
end
