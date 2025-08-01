defmodule ClaudeLive.Repo do
  use Ecto.Repo,
    otp_app: :claude_live,
    adapter: Ecto.Adapters.Postgres
end
