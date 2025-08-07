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
    project_root = find_project_root(__DIR__)
    Path.join([project_root, "db", "claude_live_#{env}.db"])
  end

  defp find_project_root(path) do
    abs_path = Path.expand(path)

    if String.contains?(abs_path, "/repo/") do
      abs_path
      |> String.split("/repo/")
      |> List.first()
    else
      find_mix_root(abs_path)
    end
  end

  defp find_mix_root(path) do
    mix_file = Path.join(path, "mix.exs")

    cond do
      File.exists?(mix_file) ->
        path

      Path.dirname(path) == path ->
        raise """
        Could not find project root (no mix.exs found).
        Started searching from: #{path}

        You can set CLAUDE_LIVE_DATABASE_PATH to specify a custom database location.
        """

      true ->
        find_mix_root(Path.dirname(path))
    end
  end
end
