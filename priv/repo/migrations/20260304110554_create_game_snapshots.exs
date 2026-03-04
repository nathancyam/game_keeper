defmodule GameKeeper.Repo.Migrations.CreateGameSnapshots do
  use Ecto.Migration

  def change do
    create table(:game_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :offset, :integer, null: false
      add :snapshot, :map, null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:game_snapshots, [:game_id])

    # Ensures that snapshots are unique (i.e. the same offset can not be used twice)
    create unique_index(:game_snapshots, [:game_id, :offset])
  end
end
