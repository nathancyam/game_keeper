defmodule GameKeeper.Repo.Migrations.CreateGameEventLogs do
  use Ecto.Migration

  def change do
    create table(:game_event_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :value, :string
      add :metadata, :map
      add :occurred_at, :utc_datetime_usec
      add :offset, :integer
      add :module, :string

      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:game_event_logs, [:game_id])
    create index(:game_event_logs, [:game_id, :offset])
    create index(:game_event_logs, [:occurred_at])
  end
end
