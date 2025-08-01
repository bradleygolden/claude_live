defmodule ClaudeLive.Claude.Session do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer,
    extensions: [AshOban]

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:pending, :running, :completed, :error]
      default :pending
    end

    attribute :cwd, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :worktree, ClaudeLive.Claude.Worktree do
      allow_nil? false
      attribute_type :uuid
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    update :create_worktree do
      require_atomic? false
      
      change fn changeset, _context ->
        session = changeset.data
        |> Ash.load!(worktree: :project, authorize?: false)
        
        worktree = session.worktree
        project = worktree.project
        
        # Create the worktree
        case ClaudeLive.Claude.Session.create_git_worktree(worktree.branch, project.path) do
          {:ok, worktree_path} ->
            # Update changeset with the worktree path and status
            changeset
            |> Ash.Changeset.change_attribute(:cwd, worktree_path)
            |> Ash.Changeset.change_attribute(:status, :ready)
            
          {:error, _reason} ->
            # Update changeset with error status
            changeset
            |> Ash.Changeset.change_attribute(:status, :error)
        end
      end
    end
  end

  oban do
    triggers do
      trigger :setup_worktree do
        action :create_worktree
        where expr(status == :pending)
        worker_module_name ClaudeLive.Workers.SetupWorktree
        scheduler_module_name ClaudeLive.Schedulers.SetupWorktree
        scheduler_cron "*/10 * * * * *"  # Check every 10 seconds
      end
    end
  end

  sqlite do
    table "sessions"
    repo ClaudeLive.Repo
  end

  def create_git_worktree(branch, project_path) do
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
end
