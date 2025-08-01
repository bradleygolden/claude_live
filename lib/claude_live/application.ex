defmodule ClaudeLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClaudeLiveWeb.Telemetry,
      ClaudeLive.Repo,
      {DNSCluster, query: Application.get_env(:claude_live, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ClaudeLive.PubSub},
      # Start a worker by calling: ClaudeLive.Worker.start_link(arg)
      # {ClaudeLive.Worker, arg},
      # Start to serve requests, typically the last entry
      ClaudeLiveWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClaudeLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClaudeLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
