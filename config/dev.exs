import Config

Code.require_file("helpers.exs", __DIR__)

config :claude_live, ClaudeLive.Repo,
  database: ClaudeLive.Config.Helpers.database_path(:dev),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :claude_live, ClaudeLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "r9xlY4AumqOM1Fb8GvgRgL2dKFJxkPTgwu8YdeGyQQxTQ3aLmSknwYKDF4hR6fCh",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:claude_live, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:claude_live, ~w(--watch)]}
  ]

config :claude_live, ClaudeLiveWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    notify: [
      live_view: [
        ~r"lib/claude_live_web/core_components.ex$",
        ~r"lib/claude_live_web/(live|components)/.*\.(ex|heex)$"
      ]
    ],
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/claude_live_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

config :claude_live, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_tags_location: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false
