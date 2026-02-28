defmodule GameKeeper.Games do
  use Boundary, deps: [GameKeeper.Repo, GameKeeper.Schemas, GameKeeper.Sports]

  alias Ecto.Changeset
  alias GameKeeper.Repo
  alias GameKeeper.Games.EventLog

  defdelegate start_event_log(game_id), to: EventLog

  defdelegate log_scores(game_id, events), to: EventLog

  def create_game(sport, name) do
    %GameKeeper.Schemas.Game{}
    |> Changeset.cast(%{sport: sport, name: name}, [:sport, :name])
    |> Changeset.validate_required([:sport, :name])
    |> Repo.insert()
  end

  def insert_score_event(game_id, %GameKeeper.Sports.Basketball.ScoreEvent{} = event) do
    %GameKeeper.Schemas.Game{id: game_id}
    |> dbg()
    |> Ecto.build_assoc(:events)
    |> Changeset.cast(
      %{
        type: :score,
        value: event.points,
        occurred_at: event.occurred_at
      },
      [:type, :value, :occured_at]
    )
    |> Changeset.validate_required([:type, :value, :occured_at])
    |> Changeset.assoc_constraint(:game)
    |> dbg()
    |> Repo.insert()
  end
end
