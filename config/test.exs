import Config
config :claude_live, Oban, testing: :manual
config :ash, disable_async?: true

Code.require_file("helpers.exs", __DIR__)

partition = System.get_env("MIX_TEST_PARTITION") || ""
test_db_name = if partition == "", do: "test", else: "test#{partition}"

config :claude_live, ClaudeLive.Repo,
  database: ClaudeLive.Config.Helpers.database_path(test_db_name),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :claude_live, ClaudeLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "bcRaBsC3cAiFtVSPaxf3ogG754YPuigCeA0gmNgVJ88pGfmmRiESdiW9gpGlBo9K",
  server: false

# In test we don't send emails
config :claude_live, ClaudeLive.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
