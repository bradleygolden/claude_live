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
    belongs_to :project, ClaudeLive.Claude.Project do
      allow_nil? false
      attribute_type :uuid
    end

    has_many :sessions, ClaudeLive.Claude.Session
  end

  actions do
    defaults [:read, update: :*]

    create :create do
      primary? true
      accept [:branch, :project_id]
      
      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.after_action(fn changeset, worktree ->
          project = Ash.load!(worktree, :project, authorize?: false).project
          
          case create_git_worktree(worktree.branch, project.path) do
            {:ok, worktree_path} ->
              # Update the worktree with the path
              worktree
              |> Ash.Changeset.for_update(:update, %{path: worktree_path})
              |> Ash.update!(authorize?: false)
              
            {:error, reason} ->
              # Return error which will rollback the transaction
              {:error, Ash.Error.Unknown.exception(error: reason)}
          end
        end)
      end
    end

    destroy :destroy do
      primary? true
      
      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.before_action(fn changeset ->
          worktree = changeset.data
          
          if worktree.path && File.exists?(worktree.path) do
            project = Ash.load!(worktree, :project, authorize?: false).project
            
            case remove_git_worktree(worktree.path, project.path) do
              {:ok, _} -> changeset
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

  defp create_git_worktree(branch, project_path) do
    worktree_name = "claude-#{branch}-#{:os.system_time(:second)}"
    worktree_path = Path.join([project_path, "..", "#{Path.basename(project_path)}-worktrees", worktree_name])

    cmd = "git"
    args = ["worktree", "add", "-b", branch, worktree_path]

    case System.cmd(cmd, args, cd: project_path, stderr_to_stdout: true) do
      {_output, 0} ->
        {:ok, worktree_path}
      
      {output, _status} ->
        {:error, output}
    end
  end

  defp remove_git_worktree(worktree_path, project_path) do
    cmd = "git"
    args = ["worktree", "remove", worktree_path, "--force"]

    case System.cmd(cmd, args, cd: project_path, stderr_to_stdout: true) do
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
end
