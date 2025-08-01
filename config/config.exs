import Config

config :ash_oban, pro?: false

config :claude_live, Oban,
  engine: Oban.Engines.Lite,
  notifier: Oban.Notifiers.PG,
  queues: [default: 10],
  repo: ClaudeLive.Repo,
  plugins: [{Oban.Plugins.Cron, []}]

config :claude_live,
  ecto_repos: [ClaudeLive.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [ClaudeLive.Claude]

config :claude_live, ClaudeLiveWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ClaudeLiveWeb.ErrorHTML, json: ClaudeLiveWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ClaudeLive.PubSub,
  live_view: [signing_salt: "MPEpwV6M"]

config :claude_live, ClaudeLive.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.25.4",
  claude_live: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.7",
  claude_live: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
