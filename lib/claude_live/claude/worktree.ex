defmodule ClaudeLive.Claude.Worktree do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :branch, :string do
      allow_nil? false
      public? true
    end

    attribute :path, :string do
      allow_nil? true
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :repository, ClaudeLive.Claude.Repository do
      allow_nil? false
      attribute_type :uuid
    end

    has_many :sessions, ClaudeLive.Claude.Session
  end

  actions do
    defaults [:read, update: :*]

    create :create do
      primary? true
      accept [:branch, :repository_id]

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.after_action(fn changeset, worktree ->
          repository = Ash.load!(worktree, :repository, authorize?: false).repository

          case create_git_worktree(worktree.branch, repository.path) do
            {:ok, worktree_path} ->
              ClaudeLive.WorktreeDatabase.setup_worktree_database(worktree_path)

              updated_worktree =
                worktree
                |> Ash.Changeset.for_update(:update, %{path: worktree_path})
                |> Ash.update!(authorize?: false)

              {:ok, updated_worktree}

            {:error, reason} when is_binary(reason) ->
              {:error, Ash.Error.Unknown.exception(message: reason)}

            {:error, reason} ->
              {:error, reason}
          end
        end)
      end
    end

    destroy :destroy do
      primary? true
      require_atomic? false

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.before_action(fn changeset ->
          worktree = changeset.data

          if worktree.path && File.exists?(worktree.path) do
            repository = Ash.load!(worktree, :repository, authorize?: false).repository

            case remove_git_worktree(worktree.path, repository.path) do
              :ok ->
                changeset

              {:error, reason} ->
                Ash.Changeset.add_error(changeset, error: reason)
            end
          else
            changeset
          end
        end)
      end
    end
  end

  defp create_git_worktree(branch, repository_path) do
    with {_output, 0} <-
           System.cmd("git", ["fetch", "origin"], cd: repository_path, stderr_to_stdout: true) do
      repo_name = Path.basename(repository_path)

      sanitized_branch = String.replace(branch, ~r/[^a-zA-Z0-9_-]/, "-")
      worktree_name = "#{sanitized_branch}-#{:os.system_time(:second)}"

      claude_live_path =
        Path.join([System.user_home!(), "Development", "bradleygolden", "claude_live"])

      worktree_path =
        Path.join([
          claude_live_path,
          "repo",
          repo_name,
          worktree_name
        ])

      worktree_parent = Path.dirname(worktree_path)
      File.mkdir_p!(worktree_parent)

      default_branch = get_default_branch(repository_path)

      cmd = "git"
      args = ["worktree", "add", "-b", branch, worktree_path, "origin/#{default_branch}"]

      case System.cmd(cmd, args, cd: repository_path, stderr_to_stdout: true) do
        {_output, 0} ->
          {:ok, worktree_path}

        {output, _status} ->
          {:error, output}
      end
    else
      {output, _status} ->
        {:error, "Failed to fetch from origin: #{output}"}
    end
  end

  defp get_default_branch(repository_path) do
    case System.cmd("git", ["symbolic-ref", "refs/remotes/origin/HEAD"],
           cd: repository_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output
        |> String.trim()
        |> String.split("/")
        |> List.last()

      _ ->
        case System.cmd("git", ["branch", "-r"], cd: repository_path, stderr_to_stdout: true) do
          {output, 0} ->
            cond do
              String.contains?(output, "origin/main") -> "main"
              String.contains?(output, "origin/master") -> "master"
              true -> "main"
            end

          _ ->
            "main"
        end
    end
  end

  defp remove_git_worktree(worktree_path, repository_path) do
    cmd = "git"
    args = ["worktree", "remove", worktree_path, "--force"]

    case System.cmd(cmd, args, cd: repository_path, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _status} ->
        {:error, output}
    end
  end

  sqlite do
    table "worktrees"
    repo ClaudeLive.Repo
  end

  identities do
    identity :unique_branch_per_repository, [:repository_id, :branch]
  end
end
