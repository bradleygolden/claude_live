defmodule ClaudeLiveWeb.TerminalLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(%{"worktree_id" => worktree_id}, _session, socket) do
    all_repositories = ClaudeLive.Claude.Repository |> Ash.read!(load: :worktrees)
    all_worktrees = all_repositories |> Enum.flat_map(& &1.worktrees)

    case Ash.get(ClaudeLive.Claude.Worktree, worktree_id, load: :repository) do
      {:ok, worktree} ->
        current_repository = Enum.find(all_repositories, &(&1.id == worktree.repository_id))

        socket =
          socket
          |> assign(:worktree, worktree)
          |> assign(:worktrees, all_worktrees)
          |> assign(:repositories, all_repositories)
          |> assign(:current_repository, current_repository)
          |> assign(:page_title, "Terminal - All Repositories")
          |> assign(:active_terminal_id, nil)

        {:ok, socket}

      {:error, _} ->
        # If worktree not found, redirect to first available worktree or dashboard
        case all_worktrees do
          [first | _] ->
            {:ok, push_navigate(socket, to: ~p"/terminal/#{first.id}")}

          [] ->
            # No worktrees available, redirect to dashboard  
            case all_repositories do
              [first_repo | _] ->
                {:ok, push_navigate(socket, to: ~p"/dashboard/#{first_repo.id}")}

              [] ->
                {:ok, push_navigate(socket, to: ~p"/")}
            end
        end
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    case params do
      %{"terminal_id" => terminal_id} ->
        {:noreply,
         socket
         |> assign(:active_terminal_id, terminal_id)
         |> push_event("switch_terminal", %{terminal_id: terminal_id})}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_terminal", %{"worktree_id" => wt_id}, socket) do
    terminal_number = find_next_terminal_number(socket.assigns.global_terminals, wt_id)
    terminal_id = "#{wt_id}-#{terminal_number}"
    session_id = "terminal-#{wt_id}-#{terminal_number}"
    worktree = Enum.find(socket.assigns.worktrees, &(&1.id == wt_id))

    terminal = %{
      id: terminal_id,
      worktree_id: wt_id,
      worktree_branch: worktree.branch,
      worktree_path: worktree.path,
      session_id: session_id,
      connected: false,
      terminal_data: "",
      name: "Terminal #{terminal_number}"
    }

    ClaudeLive.TerminalManager.upsert_terminal(terminal_id, terminal)

    {:noreply,
     socket
     |> assign(:active_terminal_id, terminal_id)
     |> push_event("switch_terminal", %{terminal_id: terminal_id})}
  end

  @impl true
  def handle_event("switch_terminal", %{"terminal_id" => terminal_id}, socket) do
    {:noreply,
     socket
     |> assign(:active_terminal_id, terminal_id)
     |> push_event("switch_terminal", %{terminal_id: terminal_id})}
  end

  @impl true
  def handle_event("rename_terminal", %{"terminal_id" => terminal_id, "name" => name}, socket) do
    if terminal = Map.get(socket.assigns.global_terminals, terminal_id) do
      updated_terminal = Map.put(terminal, :name, name)
      ClaudeLive.TerminalManager.upsert_terminal(terminal_id, updated_terminal)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_terminal", %{"terminal_id" => terminal_id}, socket) do
    terminal = Map.get(socket.assigns.global_terminals, terminal_id)

    if terminal && terminal.connected do
      ClaudeLive.Terminal.PtyServer.unsubscribe(terminal.session_id, self())
      ClaudeLive.Terminal.Supervisor.stop_terminal(terminal.session_id)
    end

    ClaudeLive.TerminalManager.delete_terminal(terminal_id)

    new_active =
      if socket.assigns.active_terminal_id == terminal_id do
        remaining_terminals = Map.delete(socket.assigns.global_terminals, terminal_id)

        case Map.keys(remaining_terminals) do
          [] -> nil
          keys -> List.first(keys)
        end
      else
        socket.assigns.active_terminal_id
      end

    socket = assign(socket, :active_terminal_id, new_active)

    if new_active do
      {:noreply, push_event(socket, "switch_terminal", %{terminal_id: new_active})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "connect",
        %{"cols" => cols, "rows" => rows, "terminal_id" => terminal_id},
        socket
      ) do
    terminals = socket.assigns[:global_terminals] || %{}
    terminal = Map.get(terminals, terminal_id)
    session_id = terminal.session_id

    if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
      ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())

      case ClaudeLive.Terminal.PtyServer.get_buffer(session_id) do
        {:ok, buffer} ->
          Enum.each(buffer, fn data ->
            send(self(), {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}})
          end)

        _ ->
          :ok
      end

      ClaudeLive.Terminal.PtyServer.resize(session_id, cols, rows)
    else
      {:ok, _pid} = ClaudeLive.Terminal.Supervisor.start_terminal(session_id)
      ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())

      :ok =
        ClaudeLive.Terminal.PtyServer.spawn_shell(session_id,
          cols: cols,
          rows: rows,
          shell: System.get_env("SHELL", "/bin/bash"),
          cwd: terminal.worktree_path
        )
    end

    terminal = Map.get(socket.assigns.global_terminals, terminal_id)

    if terminal do
      updated_terminal = Map.put(terminal, :connected, true)
      ClaudeLive.TerminalManager.upsert_terminal(terminal_id, updated_terminal)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("input", %{"data" => data, "terminal_id" => terminal_id}, socket) do
    terminals = socket.assigns[:global_terminals] || %{}
    terminal = Map.get(terminals, terminal_id)

    if terminal && Map.get(terminal, :connected, false) do
      ClaudeLive.Terminal.PtyServer.write(terminal.session_id, data)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "resize",
        %{"cols" => cols, "rows" => rows, "terminal_id" => terminal_id},
        socket
      ) do
    terminals = socket.assigns[:global_terminals] || %{}
    terminal = Map.get(terminals, terminal_id)

    if terminal && Map.get(terminal, :connected, false) do
      ClaudeLive.Terminal.PtyServer.resize(terminal.session_id, cols, rows)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("disconnect", _params, socket) do
    socket.assigns.global_terminals
    |> Enum.filter(fn {_id, t} -> t.connected end)
    |> Enum.each(fn {terminal_id, terminal} ->
      ClaudeLive.Terminal.Supervisor.stop_terminal(terminal.session_id)
      # Update status via TerminalManager
      ClaudeLive.TerminalManager.update_terminal_status(terminal_id, false)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    ClaudeLive.UIPreferences.toggle_sidebar()
    {:noreply, socket}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket) do
    terminals = socket.assigns[:global_terminals] || %{}
    terminal_id = find_terminal_by_session(terminals, session_id)

    if terminal_id do
      {:noreply, push_event(socket, "terminal_output", %{data: data, terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:terminal_updated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:terminal_deleted, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:terminal_status_updated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:terminal_activated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:ui_preference_updated, _}, socket) do
    # UI preferences are already handled by the hook
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_exit, exit_code}},
        socket
      ) do
    terminal_id = find_terminal_by_session(socket.assigns.global_terminals, session_id)

    if terminal_id do
      Logger.info("Terminal #{terminal_id} exited with code: #{exit_code}")
      ClaudeLive.TerminalManager.update_terminal_status(terminal_id, false)

      {:noreply,
       push_event(socket, "terminal_exit", %{code: exit_code, terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_closed, _status}},
        socket
      ) do
    terminal_id = find_terminal_by_session(socket.assigns.global_terminals, session_id)

    if terminal_id do
      ClaudeLive.TerminalManager.update_terminal_status(terminal_id, false)

      {:noreply, push_event(socket, "terminal_closed", %{terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    terminals =
      case socket.assigns do
        %{global_terminals: terminals_map}
        when is_map(terminals_map) and not is_struct(terminals_map) ->
          terminals_map

        _ ->
          %{}
      end

    try do
      terminals
      |> Enum.filter(fn {_id, terminal} ->
        is_map(terminal) and Map.get(terminal, :connected, false)
      end)
      |> Enum.each(fn {_id, terminal} ->
        session_id = Map.get(terminal, :session_id)

        if session_id do
          ClaudeLive.Terminal.PtyServer.unsubscribe(session_id, self())
        end
      end)
    rescue
      _ ->
        :ok
    end

    :ok
  end

  defp get_all_active_terminals_sorted(terminals) do
    terminals
    |> Enum.filter(fn {_id, terminal} -> terminal.connected end)
    |> Enum.sort_by(fn {_id, terminal} -> {terminal.worktree_branch, terminal.name} end)
  end

  defp find_terminal_by_session(%Phoenix.LiveView.Socket{} = socket, session_id) do
    find_terminal_by_session(socket.assigns[:global_terminals] || %{}, session_id)
  end

  defp find_terminal_by_session(terminals, session_id)
       when is_map(terminals) and not is_struct(terminals) do
    terminals
    |> Enum.find(fn {_id, terminal} -> terminal.session_id == session_id end)
    |> case do
      {id, _terminal} -> id
      nil -> nil
    end
  end

  defp find_terminal_by_session(_terminals, _session_id) do
    nil
  end

  defp find_next_terminal_number(terminals, worktree_id) do
    existing_numbers =
      terminals
      |> Enum.filter(fn {_id, terminal} -> terminal.worktree_id == worktree_id end)
      |> Enum.map(fn {terminal_id, _terminal} ->
        case String.split(terminal_id, "-") do
          parts when length(parts) >= 2 ->
            case Integer.parse(List.last(parts)) do
              {num, ""} -> num
              _ -> nil
            end

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    case existing_numbers do
      [] -> 1
      numbers -> find_first_gap(numbers, 1)
    end
  end

  defp find_first_gap([], current), do: current

  defp find_first_gap([num | rest], current) when num == current do
    find_first_gap(rest, current + 1)
  end

  defp find_first_gap([_num | _rest], current), do: current

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black flex">
      <!-- Sidebar -->
      <div class={[
        "bg-gray-900/95 backdrop-blur-sm border-r border-gray-800/50 flex flex-col transition-all duration-300 ease-in-out",
        (@ui_preferences.sidebar_collapsed && "w-16") || "w-72"
      ]}>
        <!-- Header with toggle button -->
        <div class="border-b border-gray-800/50">
          <div class={[
            "flex items-center justify-between",
            (@ui_preferences.sidebar_collapsed && "p-4") || "p-6"
          ]}>
            <%= if !@ui_preferences.sidebar_collapsed do %>
              <div class="flex-1">
                <h3 class="text-sm font-bold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent uppercase tracking-wider">
                  All Terminals
                </h3>
                <p class="text-xs text-gray-500 mt-2">Across {length(@repositories)} repositories</p>
              </div>
            <% end %>
            <button
              phx-click="toggle_sidebar"
              class={[
                "flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-all duration-200 cursor-pointer group",
                @ui_preferences.sidebar_collapsed && "mx-auto"
              ]}
              title={(@ui_preferences.sidebar_collapsed && "Expand sidebar") || "Collapse sidebar"}
            >
              <.icon
                name={
                  (@ui_preferences.sidebar_collapsed && "hero-chevron-right") || "hero-chevron-left"
                }
                class="w-5 h-5 text-gray-400 group-hover:text-gray-200"
              />
            </button>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto py-2">
          <% active_terminals = get_all_active_terminals_sorted(assigns.global_terminals) %>
          <%= if length(active_terminals) > 0 do %>
            <%= for {terminal_id, terminal} <- active_terminals do %>
              <% worktree = Enum.find(@worktrees, &(&1.id == terminal.worktree_id)) %>
              <% repository = Enum.find(@repositories, &(&1.id == worktree.repository_id)) %>
              <div class={[
                "mx-2 mb-1 rounded-lg group relative transition-all duration-200",
                terminal_id == @active_terminal_id &&
                  "bg-gradient-to-r from-emerald-950/30 to-cyan-950/30 shadow-lg shadow-emerald-950/20"
              ]}>
                <div class="relative flex items-center">
                  <button
                    phx-click="switch_terminal"
                    phx-value-terminal_id={terminal_id}
                    data-terminal-id={terminal_id}
                    class={[
                      "flex-1 text-left rounded-lg hover:bg-gray-800/50 transition-all duration-200 flex items-center cursor-pointer",
                      (@ui_preferences.sidebar_collapsed && "px-3 py-3 justify-center") || "px-4 py-3"
                    ]}
                    title={
                      @ui_preferences.sidebar_collapsed &&
                        "#{terminal.name} - #{repository.name}/#{worktree.branch}"
                    }
                  >
                    <%= if @ui_preferences.sidebar_collapsed do %>
                      <div class={[
                        "w-8 h-8 rounded-lg flex items-center justify-center",
                        (terminal.connected && "bg-gradient-to-br from-emerald-500 to-green-600") ||
                          "bg-gradient-to-br from-gray-600 to-gray-700"
                      ]}>
                        <.icon name="hero-command-line" class="w-4 h-4 text-white" />
                      </div>
                    <% else %>
                      <div class="flex items-center space-x-3 flex-1">
                        <div class={[
                          "w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0",
                          (terminal.connected && "bg-gradient-to-br from-emerald-500 to-green-600") ||
                            "bg-gradient-to-br from-gray-600 to-gray-700"
                        ]}>
                          <.icon name="hero-command-line" class="w-5 h-5 text-white" />
                        </div>
                        <div class="flex-1 min-w-0">
                          <div class={[
                            "text-sm font-semibold truncate",
                            (terminal.connected && "text-gray-100") || "text-gray-400"
                          ]}>
                            {terminal.name}
                          </div>
                          <div class="text-xs text-gray-500 truncate mt-0.5">
                            {repository.name} / {worktree.branch}
                          </div>
                          <div class="flex items-center gap-1 mt-1">
                            <span class={[
                              "w-1.5 h-1.5 rounded-full",
                              (terminal.connected && "bg-emerald-400 animate-pulse") || "bg-gray-600"
                            ]}>
                            </span>
                            <span class={[
                              "text-xs",
                              (terminal.connected && "text-emerald-400") || "text-gray-500"
                            ]}>
                              {(terminal.connected && "Connected") || "Disconnected"}
                            </span>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </button>
                  <%= if !@ui_preferences.sidebar_collapsed do %>
                    <button
                      phx-click="close_terminal"
                      phx-value-terminal_id={terminal_id}
                      class="absolute right-2 opacity-0 group-hover:opacity-100 flex items-center justify-center w-8 h-8 rounded-lg hover:bg-red-950/30 transition-all duration-200 cursor-pointer"
                    >
                      <.icon name="hero-x-mark" class="w-4 h-4 text-red-400" />
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% else %>
            <%= if !@ui_preferences.sidebar_collapsed do %>
              <div class="px-4 py-12 text-center">
                <div class="w-16 h-16 rounded-full bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mx-auto mb-4">
                  <.icon name="hero-command-line" class="w-8 h-8 text-gray-500" />
                </div>
                <p class="text-sm font-medium text-gray-400">No active terminals</p>
                <p class="text-xs text-gray-500 mt-2">Create terminals from the dashboard</p>
              </div>
            <% else %>
              <div class="px-2 py-4 text-center">
                <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mx-auto">
                  <.icon name="hero-command-line" class="w-5 h-5 text-gray-500" />
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <div class={[
          "border-t border-gray-800/50",
          (@ui_preferences.sidebar_collapsed && "p-2") || "p-4"
        ]}>
          <.link
            navigate={~p"/dashboard/#{@current_repository.id}"}
            class={[
              "flex items-center justify-center text-sm font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 rounded-lg transition-all duration-200 cursor-pointer",
              (@ui_preferences.sidebar_collapsed && "px-2 py-2") || "px-4 py-2"
            ]}
            title={@ui_preferences.sidebar_collapsed && "Back to Dashboard"}
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" />
            <%= if !@ui_preferences.sidebar_collapsed do %>
              <span class="ml-2">Dashboard</span>
            <% end %>
          </.link>
        </div>
      </div>

      <div class="flex-1 flex flex-col">
        <%= if @active_terminal_id && Map.get(assigns.global_terminals, @active_terminal_id) do %>
          <% active_terminal = Map.get(assigns.global_terminals, @active_terminal_id) %>
          <div class="bg-gray-900/80 backdrop-blur-sm px-6 py-3 border-b border-gray-800/50 flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
                  <.icon name="hero-command-line" class="w-4 h-4 text-white" />
                </div>
                <div>
                  <h2 class="text-white font-bold">{active_terminal.name}</h2>
                  <div class="flex items-center gap-2 text-xs">
                    <span class="text-emerald-400">{active_terminal.worktree_branch}</span>
                    <span class="text-gray-600">•</span>
                    <span class="text-gray-500 truncate max-w-md">
                      {active_terminal.worktree_path}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-2">
                <span class={[
                  "inline-block w-2 h-2 rounded-full",
                  (active_terminal.connected &&
                     "bg-emerald-400 animate-pulse shadow-emerald-400/50 shadow-sm") || "bg-red-500"
                ]}>
                </span>
                <span class={[
                  "text-sm font-medium",
                  (active_terminal.connected && "text-emerald-400") || "text-red-400"
                ]}>
                  {if active_terminal.connected, do: "Connected", else: "Disconnected"}
                </span>
              </div>
              <%= if active_terminal.connected do %>
                <button
                  phx-click="disconnect"
                  class="px-4 py-1.5 text-sm font-medium bg-red-500/20 hover:bg-red-500/30 text-red-400 rounded-lg border border-red-500/30 transition-all duration-200 cursor-pointer"
                >
                  Disconnect All
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="flex-1 relative bg-black" phx-hook="TerminalHook" id="terminal-area">
          <%= if map_size(assigns.global_terminals) == 0 do %>
            <div class="absolute inset-0 flex items-center justify-center" id="no-terminals-message">
              <div class="text-center">
                <div class="w-20 h-20 rounded-full bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center mx-auto mb-6">
                  <.icon name="hero-command-line" class="w-10 h-10 text-gray-600" />
                </div>
                <p class="text-lg font-medium text-gray-400">No terminals open</p>
                <p class="text-sm text-gray-500 mt-2">
                  Create a terminal from the dashboard to get started
                </p>
              </div>
            </div>
          <% end %>
          
    <!-- Container for all terminals - never gets re-rendered -->
          <div id="terminals-container" phx-update="ignore">
            <%= for {terminal_id, _terminal} <- Map.to_list(assigns.global_terminals) do %>
              <div
                id={"terminal-container-#{terminal_id}"}
                class="terminal-container absolute inset-0"
                style={"display: #{if terminal_id == @active_terminal_id, do: "block", else: "none"}"}
              >
                <div id={"terminal-#{terminal_id}"} class="h-full w-full"></div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
