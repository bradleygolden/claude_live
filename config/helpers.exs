defmodule ClaudeLive.Config.Helpers do
  @moduledoc """
  Configuration helpers for ClaudeLive.
  """

  @doc """
  Returns the database path for the given environment.

  Priority:
  1. CLAUDE_LIVE_DATABASE_PATH environment variable
  2. Searches for project root by finding mix.exs
  3. Returns path relative to project root: db/claude_live_<env>.db
  """
  def database_path(env) when is_atom(env) or is_binary(env) do
    System.get_env("CLAUDE_LIVE_DATABASE_PATH") || default_database_path(env)
  end

  defp default_database_path(env) do
    # Use System.find_executable to leverage Elixir's built-in path handling
    # Start from the current file's directory
    project_root = find_project_root(__DIR__)

    # Build the database path
    Path.join([project_root, "db", "claude_live_#{env}.db"])
  end

  defp find_project_root(path) do
    # Expand to absolute path
    abs_path = Path.expand(path)
    mix_file = Path.join(abs_path, "mix.exs")

    cond do
      File.exists?(mix_file) ->
        abs_path

      # Check if we're at the filesystem root
      Path.dirname(abs_path) == abs_path ->
        raise """
        Could not find project root (no mix.exs found).
        Started searching from: #{path}

        You can set CLAUDE_LIVE_DATABASE_PATH to specify a custom database location.
        """

      true ->
        # Go up one directory and continue searching
        find_project_root(Path.dirname(abs_path))
    end
  end
end
