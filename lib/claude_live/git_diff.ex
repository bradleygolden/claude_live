defmodule ClaudeLive.GitDiff do
  @moduledoc """
  Module for executing git commands and retrieving diff information.
  """

  @doc """
  Get the status of all files in the repository.
  Returns a list of file statuses with their paths and change types.
  """
  def get_status(worktree_path) do
    case System.cmd("git", ["status", "--porcelain", "-u"],
           cd: worktree_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        files =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(&parse_status_line/1)
          |> Enum.reject(&is_nil/1)

        {:ok, files}

      {error, _} ->
        {:error, error}
    end
  end

  @doc """
  Get the diff for a specific file.
  """
  def get_file_diff(worktree_path, file_path, staged \\ false) do
    args =
      if staged do
        ["diff", "--cached", "--", file_path]
      else
        ["diff", "--", file_path]
      end

    case System.cmd("git", args, cd: worktree_path, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {error, _} ->
        {:error, error}
    end
  end

  @doc """
  Get the contents of an untracked file to display as a diff.
  """
  def get_untracked_file_content(worktree_path, file_path) do
    full_path = Path.join(worktree_path, file_path)

    case File.read(full_path) do
      {:ok, content} ->
        lines = String.split(content, "\n")

        diff_output =
          ["--- /dev/null", "+++ b/#{file_path}", "@@ -0,0 +1,#{length(lines)} @@"] ++
            Enum.map(lines, fn line -> "+" <> line end)

        {:ok, Enum.join(diff_output, "\n")}

      {:error, _} ->
        {:ok, ""}
    end
  end

  @doc """
  Get all changes in the current branch compared to the base branch.
  """
  def get_branch_diff(worktree_path) do
    with {:ok, base_branch} <- get_base_branch(worktree_path),
         {:ok, current_branch} <- get_current_branch(worktree_path) do
      case System.cmd("git", ["diff", "#{base_branch}...HEAD", "--name-status"],
             cd: worktree_path,
             stderr_to_stdout: true
           ) do
        {output, 0} ->
          files =
            output
            |> String.split("\n", trim: true)
            |> Enum.map(&parse_diff_name_status/1)
            |> Enum.reject(&is_nil/1)

          {:ok,
           %{
             base_branch: base_branch,
             current_branch: current_branch,
             files: files
           }}

        {error, _} ->
          {:error, error}
      end
    end
  end

  @doc """
  Get the full diff for all changes.
  """
  def get_full_diff(worktree_path) do
    case System.cmd("git", ["diff", "HEAD"], cd: worktree_path, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {error, _} ->
        {:error, error}
    end
  end

  @doc """
  Get list of untracked files.
  """
  def get_untracked_files(worktree_path) do
    case System.cmd("git", ["ls-files", "--others", "--exclude-standard"],
           cd: worktree_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        files =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(fn path -> %{path: path, status: :untracked} end)

        {:ok, files}

      {error, _} ->
        {:error, error}
    end
  end

  defp get_base_branch(worktree_path) do
    case System.cmd("git", ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
           cd: worktree_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        branch = output |> String.trim() |> String.split("/") |> List.last()
        {:ok, "origin/#{branch}"}

      _ ->
        case System.cmd("git", ["branch", "-r"], cd: worktree_path, stderr_to_stdout: true) do
          {output, 0} ->
            cond do
              String.contains?(output, "origin/main") -> {:ok, "origin/main"}
              String.contains?(output, "origin/master") -> {:ok, "origin/master"}
              true -> {:ok, "origin/main"}
            end

          _ ->
            {:ok, "origin/main"}
        end
    end
  end

  defp get_current_branch(worktree_path) do
    case System.cmd("git", ["branch", "--show-current"],
           cd: worktree_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        {:ok, String.trim(output)}

      {error, _} ->
        {:error, error}
    end
  end

  defp parse_status_line(line) do
    case String.split_at(line, 2) do
      {status_codes, " " <> path} ->
        status = parse_status_codes(status_codes)

        %{
          path: String.trim(path),
          status: status,
          staged: String.at(status_codes, 0) != " " && String.at(status_codes, 0) != "?",
          unstaged: String.at(status_codes, 1) != " " && String.at(status_codes, 1) != "?"
        }

      _ ->
        nil
    end
  end

  defp parse_status_codes(codes) do
    case codes do
      "??" -> :untracked
      " M" -> :modified
      "M " -> :staged_modified
      "MM" -> :modified_staged_and_unstaged
      " D" -> :deleted
      "D " -> :staged_deleted
      " A" -> :added
      "A " -> :staged_added
      "AM" -> :staged_added_modified
      "AD" -> :staged_added_deleted
      " R" -> :renamed
      "R " -> :staged_renamed
      _ -> :unknown
    end
  end

  defp parse_diff_name_status(line) do
    case String.split(line, "\t", parts: 2) do
      [status, path] ->
        %{
          path: path,
          status: parse_diff_status(status)
        }

      _ ->
        nil
    end
  end

  defp parse_diff_status(status) do
    case status do
      "M" -> :modified
      "A" -> :added
      "D" -> :deleted
      "R" -> :renamed
      "C" -> :copied
      "U" -> :unmerged
      _ -> :unknown
    end
  end
end
