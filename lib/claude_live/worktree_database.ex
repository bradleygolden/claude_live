defmodule ClaudeLive.WorktreeDatabase do
  @moduledoc """
  Handles database initialization for worktrees.
  Copies the main database to the worktree if it doesn't exist.
  """

  require Logger

  @doc """
  Ensures the worktree has its own database copy.
  Called during application startup.
  """
  def ensure_database! do
    current_db_path = ClaudeLive.Config.Helpers.database_path(:dev)

    if is_worktree_path?(current_db_path) do
      Logger.info("Detected worktree environment")

      unless File.exists?(current_db_path) do
        copy_main_database_to_worktree(current_db_path)
      else
        Logger.info("Using existing worktree database: #{current_db_path}")
      end
    else
      Logger.info("Running in main repository")
    end
  end

  @doc """
  Copies database when creating a new worktree.
  Called after worktree creation in the Ash resource.
  """
  def setup_worktree_database(worktree_path) do
    worktree_db_path = Path.join([worktree_path, "db", "claude_live_dev.db"])
    ensure_db_directory!(worktree_db_path)
    copy_main_database_to_worktree(worktree_db_path)
  end

  defp is_worktree_path?(db_path) do
    String.contains?(db_path, "/repo/claude_live/") and
      not String.ends_with?(Path.dirname(Path.dirname(db_path)), "/claude_live")
  end

  defp copy_main_database_to_worktree(destination_db_path) do
    main_db_path = get_main_database_path()

    if File.exists?(main_db_path) do
      Logger.info("Copying main database: #{main_db_path} -> #{destination_db_path}")
      ensure_db_directory!(destination_db_path)
      copy_database_files(main_db_path, destination_db_path)
    else
      Logger.warning(
        "No main database found at #{main_db_path}, worktree will start with fresh database"
      )
    end
  end

  defp get_main_database_path do
    main_repo_path =
      Path.join([System.user_home!(), "Development", "bradleygolden", "claude_live"])

    Path.join([main_repo_path, "db", "claude_live_dev.db"])
  end

  defp ensure_db_directory!(db_path) do
    db_dir = Path.dirname(db_path)

    unless File.exists?(db_dir) do
      Logger.info("Creating database directory: #{db_dir}")
      File.mkdir_p!(db_dir)
    end
  end

  defp copy_database_files(source, destination) do
    case File.cp(source, destination) do
      :ok ->
        Logger.info("Successfully copied main database file")

        for suffix <- ["-wal", "-shm"] do
          source_file = source <> suffix
          dest_file = destination <> suffix

          if File.exists?(source_file) do
            case File.cp(source_file, dest_file) do
              :ok ->
                Logger.debug("Copied #{suffix} file")

              {:error, reason} ->
                Logger.warning("Could not copy #{suffix} file: #{inspect(reason)}")
            end
          end
        end

        :ok

      {:error, reason} ->
        Logger.error("Failed to copy database: #{inspect(reason)}")
        Logger.warning("Worktree will start with a fresh database")
        :error
    end
  end
end
