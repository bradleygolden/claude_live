defmodule ClaudeLiveWeb.Router do
  use ClaudeLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClaudeLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClaudeLiveWeb do
    pipe_through :browser

    # LiveViews with global terminal state management
    live_session :terminal_session,
      on_mount: {ClaudeLiveWeb.TerminalStateHook, :default} do
      live "/", DashboardLive, :index
      live "/dashboard/:repo_id", DashboardLive, :show
      live "/dashboard/browse/directory", DirectoryBrowserLive, :browse
      live "/terminals/:terminal_id", IsolatedTerminalLive, :index
    end
  end

  if Application.compile_env(:claude_live, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClaudeLiveWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
