defmodule ClaudeLiveWeb.ClaudeWebhookController do
  use ClaudeLiveWeb, :controller
  require Logger

  @doc """
  Handle webhooks with worktree ID in URL path.
  """
  def webhook_with_worktree(conn, %{"worktree_id" => worktree_id} = params) do
    Logger.info("Received Claude webhook for worktree #{worktree_id}")

    case create_event_from_webhook(conn, params, worktree_id: worktree_id) do
      {:ok, event} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "processed", event_id: event.id})

      {:error, error} ->
        Logger.error("Failed to create event: #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to process webhook"})
    end
  end

  @doc """
  Handle webhooks without worktree ID in URL.
  Uses Git information from headers for correlation.
  """
  def webhook(conn, params) do
    git_branch = get_req_header(conn, "x-git-branch") |> List.first()
    git_commit = get_req_header(conn, "x-git-commit") |> List.first()
    project_dir = get_req_header(conn, "x-project-dir") |> List.first()

    Logger.info("Received Claude webhook for branch: #{git_branch || "unknown"}")

    case create_event_from_webhook(conn, params,
           git_branch: git_branch,
           git_commit: git_commit,
           project_dir: project_dir
         ) do
      {:ok, event} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "processed", event_id: event.id})

      {:error, error} ->
        Logger.error("Failed to create event: #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to process webhook"})
    end
  end

  defp create_event_from_webhook(_conn, params, opts) do
    event_attrs = %{
      data: params,
      git_branch: opts[:git_branch],
      git_commit: opts[:git_commit],
      project_dir: opts[:project_dir],
      worktree_id: opts[:worktree_id]
    }

    Ash.create(ClaudeLive.Claude.Event, event_attrs, action: :from_webhook)
  end
end
