defmodule GameKeeper.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:game_teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      add :side, :string
      add :game_id, references(:games, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
