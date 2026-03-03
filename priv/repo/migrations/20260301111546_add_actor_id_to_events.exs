defmodule GameKeeper.Repo.Migrations.AddActorIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:game_event_logs) do
      add :actor_id, references(:game_actors, on_delete: :delete_all, type: :binary_id)

      add :team_id, references(:game_teams, on_delete: :delete_all, type: :binary_id)
    end

    create index(:game_event_logs, [:actor_id])
    create index(:game_event_logs, [:team_id])
  end
end
