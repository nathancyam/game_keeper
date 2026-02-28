defmodule GameKeeper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GameKeeperWeb.Telemetry,
      GameKeeper.Repo,
      {DNSCluster, query: Application.get_env(:game_keeper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GameKeeper.PubSub},

      # Game event processing pipelines.
      {Registry, keys: :unique, name: GameKeeper.GamesRegistry},
      {DynamicSupervisor, name: GameKeeper.Games.EventLogSupervisor, strategy: :one_for_one},
      GameKeeper.Events.Pipeline,

      # Start a worker by calling: GameKeeper.Worker.start_link(arg)
      # {GameKeeper.Worker, arg},
      # Start to serve requests, typically the last entry
      GameKeeperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameKeeper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GameKeeperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
