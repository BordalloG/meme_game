defmodule MemeGame.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MemeGameWeb.Telemetry,
      MemeGame.Repo,
      {DNSCluster, query: Application.get_env(:meme_game, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MemeGame.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MemeGame.Finch},
      # Start a worker by calling: MemeGame.Worker.start_link(arg)
      # {MemeGame.Worker, arg},
      # Start to serve requests, typically the last entry
      MemeGameWeb.Endpoint,
      # Start the Server Supervisor
      MemeGame.GameServer.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MemeGame.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MemeGameWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
