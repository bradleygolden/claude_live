defmodule ClaudeLiveWeb.ClaudeWebhookController do
  use ClaudeLiveWeb, :controller
  require Logger

  alias ClaudeLive.Claude.WebhookHandler

  def webhook(conn, params) do
    Logger.info("Received Claude webhook: #{inspect(params)}")

    {:ok, response} = WebhookHandler.handle_event(params)

    conn
    |> put_status(:ok)
    |> json(response)
  end
end
