defmodule GameKeeper.Repo do
  use Boundary

  use Ecto.Repo,
    otp_app: :game_keeper,
    adapter: Ecto.Adapters.Postgres
end
