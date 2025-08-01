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
              # Update the worktree with the path
              updated_worktree =
                worktree
                |> Ash.Changeset.for_update(:update, %{path: worktree_path})
                |> Ash.update!(authorize?: false)

              {:ok, updated_worktree}

            {:error, reason} ->
              # Return error which will rollback the transaction
              {:error, Ash.Error.Unknown.exception(message: reason)}
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
              {:ok, _} ->
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
    worktree_name = "claude-#{branch}-#{:os.system_time(:second)}"

    worktree_path =
      Path.join([
        repository_path,
        "..",
        "#{Path.basename(repository_path)}-worktrees",
        worktree_name
      ])

    cmd = "git"
    args = ["worktree", "add", "-b", branch, worktree_path]

    case System.cmd(cmd, args, cd: repository_path, stderr_to_stdout: true) do
      {_output, 0} ->
        {:ok, worktree_path}

      {output, _status} ->
        {:error, output}
    end
  end

  defp remove_git_worktree(worktree_path, repository_path) do
    cmd = "git"
    args = ["worktree", "remove", worktree_path, "--force"]

    case System.cmd(cmd, args, cd: repository_path, stderr_to_stdout: true) do
      {_output, 0} ->
        {:ok, :removed}

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
