defmodule ClaudeLiveWeb.GitDiffLive do
  @moduledoc """
  LiveView for displaying git diffs for a specific worktree.
  """
  use ClaudeLiveWeb, :live_view
  import ClaudeLiveWeb.Components.GitDiffViewer

  @impl true
  def mount(%{"worktree_id" => worktree_id}, _session, socket) do
    worktree = get_worktree(worktree_id)

    if worktree do
      socket =
        socket
        |> assign(:worktree, worktree)
        |> assign(:worktree_id, worktree_id)
        |> assign(:page_title, "Git Diff - #{worktree.name}")
        |> assign(:diff_files, [])
        |> assign(:expanded_files, MapSet.new())
        |> assign(:file_diffs, %{})
        |> assign(:auto_expand, false)
        |> assign(:diff_mode, :origin)
        |> load_git_status()

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Worktree not found")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(%{"expand" => "true"}, _url, socket) do
    {:noreply,
     socket
     |> assign(:auto_expand, true)
     |> expand_all_files()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "toggle-file-diff",
        %{"viewer-id" => viewer_id, "file-path" => file_path},
        socket
      ) do
    file_key = "#{viewer_id}:#{file_path}"
    expanded_files = socket.assigns.expanded_files

    expanded_files =
      if MapSet.member?(expanded_files, file_key) do
        MapSet.delete(expanded_files, file_key)
      else
        MapSet.put(expanded_files, file_key)
      end

    socket =
      socket
      |> assign(:expanded_files, expanded_files)
      |> load_file_diff(file_path)

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_git_status(socket)}
  end

  @impl true
  def handle_event("expand-all", _params, socket) do
    {:noreply, expand_all_files(socket)}
  end

  @impl true
  def handle_event("collapse-all", _params, socket) do
    {:noreply,
     socket
     |> assign(:expanded_files, MapSet.new())
     |> assign(:file_diffs, %{})}
  end

  @impl true
  def handle_event("toggle-diff-mode", _params, socket) do
    new_mode = if socket.assigns.diff_mode == :origin, do: :working, else: :origin

    {:noreply,
     socket
     |> assign(:diff_mode, new_mode)
     |> assign(:expanded_files, MapSet.new())
     |> assign(:file_diffs, %{})
     |> load_git_status()}
  end

  defp get_worktree(worktree_id) do
    case worktree_id do
      "terminal-" <> terminal_id ->
        terminal = ClaudeLive.TerminalManager.get_terminal(terminal_id)

        if terminal,
          do: %{
            id: worktree_id,
            name: terminal.name,
            path: terminal.worktree_path,
            branch: terminal.worktree_branch
          }

      _ ->
        try do
          ClaudeLive.Claude.Worktree
          |> Ash.get(worktree_id)
          |> case do
            {:ok, worktree} ->
              %{
                id: worktree.id,
                name: worktree.branch,
                path: worktree.path,
                branch: worktree.branch
              }

            _ ->
              nil
          end
        rescue
          _ -> nil
        end
    end
  end

  defp load_git_status(socket) do
    worktree_path = socket.assigns.worktree.path

    result =
      if socket.assigns.diff_mode == :origin do
        ClaudeLive.GitDiff.get_status_against_origin(worktree_path)
      else
        ClaudeLive.GitDiff.get_status(worktree_path)
      end

    case result do
      {:ok, files} ->
        socket
        |> assign(:diff_files, files)
        |> then(fn s ->
          if socket.assigns.auto_expand do
            expand_all_files(s)
          else
            s
          end
        end)

      {:error, _} ->
        assign(socket, :diff_files, [])
    end
  end

  defp expand_all_files(socket) do
    worktree_path = socket.assigns.worktree.path
    viewer_id = "gitdiff-#{socket.assigns.worktree_id}"
    mode = socket.assigns.diff_mode

    {expanded_files, file_diffs} =
      Enum.reduce(socket.assigns.diff_files, {MapSet.new(), %{}}, fn file, {exp_files, diffs} ->
        file_key = "#{viewer_id}:#{file.path}"
        exp_files = MapSet.put(exp_files, file_key)

        diff_content = get_file_diff_content(worktree_path, file, mode)
        diffs = if diff_content != "", do: Map.put(diffs, file_key, diff_content), else: diffs
        {exp_files, diffs}
      end)

    socket
    |> assign(:expanded_files, expanded_files)
    |> assign(:file_diffs, file_diffs)
  end

  defp load_file_diff(socket, file_path) do
    worktree_path = socket.assigns.worktree.path
    viewer_id = "gitdiff-#{socket.assigns.worktree_id}"
    file_key = "#{viewer_id}:#{file_path}"
    mode = socket.assigns.diff_mode

    file = Enum.find(socket.assigns.diff_files, &(&1.path == file_path))

    if file && MapSet.member?(socket.assigns.expanded_files, file_key) do
      diff_content = get_file_diff_content(worktree_path, file, mode)

      if diff_content != "" do
        file_diffs = Map.put(socket.assigns.file_diffs, file_key, diff_content)
        assign(socket, :file_diffs, file_diffs)
      else
        socket
      end
    else
      socket
    end
  end

  defp get_file_diff_content(worktree_path, file, mode) do
    if file.status == :untracked do
      case ClaudeLive.GitDiff.get_untracked_file_content(worktree_path, file.path) do
        {:ok, content} -> content
        _ -> ""
      end
    else
      if mode == :origin do
        case ClaudeLive.GitDiff.get_file_diff_against_origin(worktree_path, file.path) do
          {:ok, ""} ->
            case ClaudeLive.GitDiff.get_file_diff(worktree_path, file.path) do
              {:ok, ""} ->
                case ClaudeLive.GitDiff.get_file_diff(worktree_path, file.path, true) do
                  {:ok, diff} -> diff
                  _ -> ""
                end

              {:ok, diff} ->
                diff

              _ ->
                ""
            end

          {:ok, diff} ->
            diff

          _ ->
            ""
        end
      else
        case ClaudeLive.GitDiff.get_file_diff(worktree_path, file.path) do
          {:ok, ""} ->
            case ClaudeLive.GitDiff.get_file_diff(worktree_path, file.path, true) do
              {:ok, diff} -> diff
              _ -> ""
            end

          {:ok, diff} ->
            diff

          _ ->
            ""
        end
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black">
      <div class="bg-gray-900/80 backdrop-blur-sm border-b border-gray-800/50">
        <div class="container mx-auto px-6 py-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <.link
                navigate={get_back_path(assigns)}
                class="p-2 rounded-lg hover:bg-gray-800/50 transition-colors"
                title="Go back"
              >
                <.icon name="hero-arrow-left" class="w-5 h-5 text-gray-400" />
              </.link>
              <div>
                <h1 class="text-xl font-bold text-white">Git Changes</h1>
                <div class="flex items-center gap-2 mt-1">
                  <span class="text-sm text-emerald-400">{@worktree.branch}</span>
                  <span class="text-gray-600">•</span>
                  <span class="text-xs text-gray-500 truncate max-w-md">
                    {@worktree.path}
                  </span>
                </div>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              <button
                phx-click="toggle-diff-mode"
                class={[
                  "px-3 py-1.5 text-xs font-medium rounded-lg transition-colors",
                  if @diff_mode == :origin do
                    "bg-emerald-600/20 text-emerald-400 border border-emerald-600/30"
                  else
                    "bg-gray-800/50 hover:bg-gray-700/50 text-gray-300"
                  end
                ]}
                title={
                  if @diff_mode == :origin,
                    do: "Showing changes vs origin branch",
                    else: "Showing working directory changes"
                }
              >
                <%= if @diff_mode == :origin do %>
                  <.icon name="hero-arrow-path" class="w-3 h-3 inline mr-1" /> vs Origin
                <% else %>
                  <.icon name="hero-document-text" class="w-3 h-3 inline mr-1" /> Working Dir
                <% end %>
              </button>
              <button
                phx-click="expand-all"
                class="px-3 py-1.5 text-xs font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 rounded-lg transition-colors"
              >
                Expand All
              </button>
              <button
                phx-click="collapse-all"
                class="px-3 py-1.5 text-xs font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 rounded-lg transition-colors"
              >
                Collapse All
              </button>
              <button
                phx-click="refresh"
                class="p-1.5 rounded-lg hover:bg-gray-800/50 transition-colors"
                title="Refresh"
              >
                <svg
                  class="w-4 h-4 text-gray-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="container mx-auto px-6 py-8">
        <div class="max-w-6xl mx-auto">
          <%= if length(@diff_files) > 0 do %>
            <div class="mb-4 text-sm text-gray-400">
              {length(@diff_files)} file(s) changed
            </div>
          <% end %>

          <.git_diff_viewer
            id={"gitdiff-#{@worktree_id}"}
            diff_files={@diff_files}
            expanded_files={@expanded_files}
            file_diffs={@file_diffs}
            on_toggle_file="toggle-file-diff"
            class="space-y-2"
          />
        </div>
      </div>
    </div>
    """
  end

  defp get_back_path(assigns) do
    case assigns.worktree_id do
      "terminal-" <> terminal_id -> ~p"/terminals/#{terminal_id}"
      _ -> ~p"/"
    end
  end
end
