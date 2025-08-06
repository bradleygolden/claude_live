defmodule ClaudeLive.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ClaudeLive.WorktreeDatabase.ensure_database!()

    children = [
      ClaudeLiveWeb.Telemetry,
      ClaudeLive.Repo,
      {DNSCluster, query: Application.get_env(:claude_live, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:claude_live, :ash_domains),
         Application.fetch_env!(:claude_live, Oban)
       )},
      {Phoenix.PubSub, name: ClaudeLive.PubSub},
      {Registry, keys: :unique, name: ClaudeLive.Terminal.Registry},
      ClaudeLive.Terminal.Supervisor,
      ClaudeLive.TerminalManager,
      ClaudeLive.UIPreferences,
      ClaudeLiveWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ClaudeLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ClaudeLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
