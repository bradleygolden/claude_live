defmodule ClaudeLive.Claude.Worktree do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer,
    extensions: [AshArchival.Resource]

  archive do
    attribute :archived_at
    exclude_read_actions([:archived, :with_archived])
  end

  attributes do
    uuid_primary_key :id

    attribute :branch, :string do
      allow_nil? false
      public? true
    end

    attribute :directory_name, :string do
      allow_nil? true
      public? true
    end

    attribute :display_name, :string do
      allow_nil? true
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

    read :archived do
      filter expr(not is_nil(archived_at))
    end

    read :with_archived do
    end

    update :unarchive do
      accept []
      require_atomic? false
      change set_attribute(:archived_at, nil)
      skip_unknown_inputs [:updated_at]

      # Disable stale record check since we're working with archived records
      change fn changeset, _context ->
        Map.put(changeset, :check_stale_record?, false)
      end
    end

    create :create do
      primary? true
      accept [:branch, :repository_id, :directory_name, :display_name]

      change fn changeset, _context ->
        # Set display_name to branch if not provided
        display_name =
          Ash.Changeset.get_attribute(changeset, :display_name) ||
            Ash.Changeset.get_attribute(changeset, :branch)

        changeset =
          changeset
          |> Ash.Changeset.change_attribute(:display_name, display_name)

        changeset
        |> Ash.Changeset.after_action(fn changeset, worktree ->
          repository = Ash.load!(worktree, :repository, authorize?: false).repository

          case create_git_worktree(worktree, repository.path) do
            {:ok, worktree_path, directory_name} ->
              ClaudeLive.WorktreeDatabase.setup_worktree_database(worktree_path)

              updated_worktree =
                worktree
                |> Ash.Changeset.for_update(:update, %{
                  path: worktree_path,
                  directory_name: directory_name
                })
                |> Ash.update!(authorize?: false)

              {:ok, updated_worktree}

            {:error, reason} when is_binary(reason) ->
              {:error, Ash.Error.Unknown.exception(error: reason)}

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

          # Try to remove the git worktree if path exists
          # But don't fail the destroy if it's already gone
          if worktree.path do
            repository = Ash.load!(worktree, :repository, authorize?: false).repository

            # Attempt to remove git worktree, but don't block database deletion
            case remove_git_worktree(worktree.path, repository.path) do
              :ok ->
                changeset

              {:error, _reason} ->
                # Log the error but continue with destroy
                # The worktree might already be gone
                changeset
            end
          else
            changeset
          end
        end)
      end
    end
  end

  defp create_git_worktree(worktree, repository_path) do
    with {_output, 0} <-
           System.cmd("git", ["fetch", "origin"], cd: repository_path, stderr_to_stdout: true) do
      repo_name = Path.basename(repository_path)

      claude_live_path =
        Path.join([System.user_home!(), "Development", "bradleygolden", "claude_live"])

      repo_base_path = Path.join([claude_live_path, "repo", repo_name])

      # Generate collision-safe directory name
      directory_name = generate_safe_directory_name(worktree.branch, repo_base_path)

      worktree_path = Path.join(repo_base_path, directory_name)
      worktree_parent = Path.dirname(worktree_path)
      File.mkdir_p!(worktree_parent)

      default_branch = get_default_branch(repository_path)

      cmd = "git"
      args = ["worktree", "add", "-b", worktree.branch, worktree_path, "origin/#{default_branch}"]

      case System.cmd(cmd, args, cd: repository_path, stderr_to_stdout: true) do
        {_output, 0} ->
          {:ok, worktree_path, directory_name}

        {output, _status} ->
          cond do
            String.contains?(output, ["already exists", "is not empty"]) ->
              {:error,
               "A worktree directory already exists at this location. This may be from a previously archived worktree. Please manually remove the directory or choose a different branch name."}

            String.contains?(output, "already checked out") ->
              {:error, "This branch is already checked out in another worktree."}

            true ->
              {:error, "Failed to create worktree: #{output}"}
          end
      end
    else
      {output, _status} ->
        {:error, "Failed to fetch from origin: #{output}"}
    end
  end

  defp generate_safe_directory_name(branch, repo_base_path) do
    sanitized_branch = String.replace(branch, ~r/[^a-zA-Z0-9_-]/, "-")

    # Try the branch name first
    if !File.exists?(Path.join(repo_base_path, sanitized_branch)) do
      sanitized_branch
    else
      # If collision, append number
      find_next_available_name(sanitized_branch, repo_base_path)
    end
  end

  defp find_next_available_name(base_name, repo_base_path, counter \\ 2) do
    candidate = "#{base_name}-#{counter}"

    if !File.exists?(Path.join(repo_base_path, candidate)) do
      candidate
    else
      find_next_available_name(base_name, repo_base_path, counter + 1)
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

      {output, status} ->
        if status == 128 &&
             String.contains?(output, ["is not a working tree", "is not a git repository"]) do
          System.cmd("git", ["worktree", "prune"], cd: repository_path, stderr_to_stdout: true)
          :ok
        else
          {:error, output}
        end
    end
  end

  sqlite do
    table "worktrees"
    repo ClaudeLive.Repo
  end

  identities do
    identity :unique_branch_per_repository, [:repository_id, :branch]
  end

  def sync_worktrees_with_git(repository) do
    repository = Ash.load!(repository, :worktrees, authorize?: false)

    case System.cmd("git", ["worktree", "list"], cd: repository.path, stderr_to_stdout: true) do
      {output, 0} ->
        git_worktree_paths =
          output
          |> String.split("\n")
          |> Enum.map(&(String.split(&1, " ") |> List.first()))
          |> Enum.filter(&(&1 && &1 != "" && &1 != repository.path))
          |> MapSet.new()

        orphaned_worktrees =
          repository.worktrees
          |> Enum.filter(fn worktree ->
            worktree.path && !MapSet.member?(git_worktree_paths, worktree.path)
          end)

        results =
          Enum.map(orphaned_worktrees, fn worktree ->
            case Ash.destroy(worktree, authorize?: false) do
              :ok -> {:ok, worktree.branch}
              error -> {:error, worktree.branch, error}
            end
          end)

        System.cmd("git", ["worktree", "prune"], cd: repository.path, stderr_to_stdout: true)

        {:ok, results}

      {error, _status} ->
        {:error, "Failed to list git worktrees: #{error}"}
    end
  end
end
