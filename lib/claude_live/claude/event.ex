defmodule ClaudeLive.Claude.Event do
  @moduledoc """
  Captures all Claude Code webhook events for history and analysis.
  """

  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :event_type, :atom do
      allow_nil? false
      public? true

      constraints one_of: [
                    :stop,
                    :subagent_stop,
                    :tool_used,
                    :before_tool_use,
                    :notification,
                    :session_start,
                    :user_prompt,
                    :file_change,
                    :git_command
                  ]
    end

    attribute :tool_name, :string do
      allow_nil? true
      public? true
    end

    attribute :file_path, :string do
      allow_nil? true
      public? true
    end

    attribute :command, :string do
      allow_nil? true
      public? true
    end

    attribute :data, :map do
      allow_nil? false
      public? true
      default %{}
    end

    attribute :session_id, :string do
      allow_nil? true
      public? true
    end

    attribute :git_branch, :string do
      allow_nil? true
      public? true
    end

    attribute :git_commit, :string do
      allow_nil? true
      public? true
    end

    attribute :project_dir, :string do
      allow_nil? true
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :worktree, ClaudeLive.Claude.Worktree do
      allow_nil? true
      attribute_type :uuid
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :event_type,
        :tool_name,
        :file_path,
        :command,
        :data,
        :session_id,
        :worktree_id,
        :git_branch,
        :git_commit,
        :project_dir
      ]
    end

    create :from_webhook do
      accept [:data, :git_branch, :git_commit, :project_dir]

      change fn changeset, _context ->
        params = Ash.Changeset.get_argument(changeset, :data) || %{}
        event_type = params["hook_event_name"] || params["event"] || "unknown"

        worktree_id =
          find_worktree(
            Ash.Changeset.get_argument(changeset, :git_branch),
            Ash.Changeset.get_argument(changeset, :project_dir)
          )

        changeset
        |> Ash.Changeset.change_attribute(:event_type, normalize_event_type(event_type))
        |> Ash.Changeset.change_attribute(:tool_name, params["tool_name"])
        |> Ash.Changeset.change_attribute(:session_id, get_session_id(params))
        |> Ash.Changeset.change_attribute(:worktree_id, worktree_id)
        |> Ash.Changeset.change_attribute(:file_path, get_in(params, ["tool_input", "file_path"]))
        |> Ash.Changeset.change_attribute(:command, get_in(params, ["tool_input", "command"]))
      end
    end

    read :recent do
      prepare build(limit: 50, sort: [inserted_at: :desc])
    end

    read :by_worktree do
      argument :worktree_id, :uuid, allow_nil?: false
      filter expr(worktree_id == ^arg(:worktree_id))
      prepare build(sort: [inserted_at: :desc])
    end
  end

  sqlite do
    table "claude_events"
    repo ClaudeLive.Repo
  end

  defp find_worktree(nil, _), do: nil
  defp find_worktree(_, nil), do: nil

  defp find_worktree(branch, path) do
    case Ash.read(ClaudeLive.Claude.Worktree,
           filter: [branch: branch, path: path]
         ) do
      {:ok, [worktree | _]} ->
        worktree.id

      _ ->
        case Ash.read(ClaudeLive.Claude.Worktree, filter: [branch: branch]) do
          {:ok, [worktree | _]} -> worktree.id
          _ -> nil
        end
    end
  rescue
    _ -> nil
  end

  defp normalize_event_type(event_type) when is_binary(event_type) do
    event_type
    |> Macro.underscore()
    |> String.replace(" ", "_")
    |> String.to_atom()
  rescue
    _ -> :unknown
  end

  defp normalize_event_type(_), do: :unknown

  defp get_session_id(params) do
    params["session_id"] ||
      params["claude_session_id"] ||
      get_in(params, ["context", "session_id"])
  end
end
