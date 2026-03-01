defmodule GameKeeper.Repo.Migrations.CreateGameActors do
  use Ecto.Migration

  def change do
    create table(:game_actors, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :type, :string, comment: "The type of the actor, e.g. 'player', 'coach', 'volunteer'"
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id), null: false
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:game_actors, [:game_id])
  end
end
