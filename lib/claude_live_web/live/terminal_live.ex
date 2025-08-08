defmodule ClaudeLiveWeb.TerminalLive do
  @moduledoc """
  LiveView for a single terminal instance.
  Each terminal runs at /terminal/:terminal_id providing complete isolation.
  """
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(%{"terminal_id" => terminal_id}, _session, socket) do
    terminal = ClaudeLive.TerminalManager.get_terminal(terminal_id)

    if terminal do
      ClaudeLive.TerminalManager.subscribe()

      socket =
        socket
        |> assign(:terminal_id, terminal_id)
        |> assign(:terminal, terminal)
        |> assign(:session_id, terminal.session_id)
        |> assign(:subscribed, false)
        |> assign(:page_title, "Terminal - #{terminal.name}")
        |> assign(:global_terminals, ClaudeLive.TerminalManager.list_terminals())
        |> assign(:sidebar_collapsed, false)
        |> push_event("load-sidebar-state", %{})

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Terminal not found")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("connect", %{"cols" => cols, "rows" => rows}, socket) do
    session_id = socket.assigns.session_id
    terminal = socket.assigns.terminal

    if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
      unless socket.assigns.subscribed do
        ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())
      end

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

    updated_terminal = Map.put(terminal, :connected, true)
    ClaudeLive.TerminalManager.upsert_terminal(socket.assigns.terminal_id, updated_terminal)

    {:noreply, assign(socket, :subscribed, true)}
  end

  @impl true
  def handle_event("input", %{"data" => data}, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.write(socket.assigns.session_id, data)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("resize", %{"cols" => cols, "rows" => rows}, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.resize(socket.assigns.session_id, cols, rows)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("disconnect", _params, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.unsubscribe(socket.assigns.session_id, self())
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-in-iterm", _params, socket) do
    path = socket.assigns.terminal.worktree_path
    encoded_path = URI.encode(path)
    command = URI.encode("cd #{path} && claude code")
    iterm_url = "iterm2://app/command?d=#{encoded_path}&c=#{command}"

    {:noreply,
     socket
     |> push_event("open-url", %{url: iterm_url})
     |> put_flash(:info, "Opening in iTerm2...")}
  end

  @impl true
  def handle_event("open-in-zed", _params, socket) do
    path = socket.assigns.terminal.worktree_path

    case System.cmd("zed", [path], stderr_to_stdout: true) do
      {_output, 0} ->
        {:noreply, put_flash(socket, :info, "Opening in Zed...")}

      {_output, _status} ->
        zed_url = "zed://file/#{URI.encode(path)}"

        {:noreply,
         socket
         |> push_event("open-url", %{url: zed_url})
         |> put_flash(:info, "Opening in Zed...")}
    end
  end

  @impl true
  def handle_event("close-terminal", %{"terminal-id" => terminal_id}, socket) do
    case ClaudeLive.TerminalManager.delete_terminal(terminal_id) do
      :ok ->
        if terminal_id == socket.assigns.terminal_id do
          remaining_terminals = ClaudeLive.TerminalManager.list_terminals()

          if map_size(remaining_terminals) > 0 do
            {first_id, _} = Enum.at(remaining_terminals, 0)
            {:noreply, push_navigate(socket, to: ~p"/terminals/#{first_id}")}
          else
            {:noreply, push_navigate(socket, to: ~p"/")}
          end
        else
          {:noreply,
           assign(socket, :global_terminals, ClaudeLive.TerminalManager.list_terminals())}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Terminal not found")}
    end
  end

  def handle_event("toggle-sidebar", _params, socket) do
    new_state = !socket.assigns.sidebar_collapsed

    {:noreply,
     socket
     |> assign(:sidebar_collapsed, new_state)
     |> push_event("store-sidebar-state", %{collapsed: new_state})}
  end

  def handle_event("sidebar-state-loaded", %{"collapsed" => collapsed}, socket) do
    {:noreply, assign(socket, :sidebar_collapsed, collapsed)}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket) do
    if session_id == socket.assigns.session_id do
      {:noreply, push_event(socket, "terminal_output", %{data: data})}
    else
      Logger.warning(
        "Terminal #{socket.assigns.terminal_id} received data for wrong session: #{session_id}"
      )

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_exit, exit_code}},
        socket
      ) do
    if session_id == socket.assigns.session_id do
      Logger.info("Terminal #{socket.assigns.terminal_id} exited with code: #{exit_code}")
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)

      {:noreply, push_event(socket, "terminal_exit", %{code: exit_code})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_closed, _status}},
        socket
      ) do
    if session_id == socket.assigns.session_id do
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)

      {:noreply, push_event(socket, "terminal_closed", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:terminal_updated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:terminal_deleted, deleted_terminal_id}, socket) do
    updated_socket =
      assign(socket, :global_terminals, ClaudeLive.TerminalManager.list_terminals())

    if deleted_terminal_id == socket.assigns.terminal_id do
      remaining_terminals = updated_socket.assigns.global_terminals

      if map_size(remaining_terminals) > 0 do
        {first_id, _} = Enum.at(remaining_terminals, 0)
        {:noreply, push_navigate(updated_socket, to: ~p"/terminals/#{first_id}")}
      else
        {:noreply, push_navigate(updated_socket, to: ~p"/")}
      end
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_info({:ui_preference_updated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:subscribed] && socket.assigns[:session_id] do
      try do
        ClaudeLive.Terminal.PtyServer.unsubscribe(socket.assigns.session_id, self())
      rescue
        _ -> :ok
      end
    end

    :ok
  end

  defp get_dashboard_link(terminal) do
    if terminal.worktree_id do
      case get_repository_id(terminal.worktree_id) do
        {:ok, repo_id} -> ~p"/dashboard/#{repo_id}"
        _ -> ~p"/"
      end
    else
      ~p"/"
    end
  end

  defp get_repository_id(worktree_id) do
    try do
      worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)
      {:ok, worktree.repository_id}
    rescue
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="terminal-container"
      class="h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black flex"
      phx-hook="SidebarState"
    >
      <!-- Sidebar with terminals list -->
      <div class={[
        "bg-gray-900/95 backdrop-blur-sm border-r border-gray-800/50 flex flex-col transition-all duration-300 ease-in-out overflow-hidden",
        if @sidebar_collapsed do
          "w-14"
        else
          "w-72"
        end
      ]}>
        <!-- Header -->
        <div class="border-b border-gray-800/50">
          <div class={[
            "transition-all duration-300",
            if @sidebar_collapsed do
              "p-3"
            else
              "p-6"
            end
          ]}>
            <div class="flex items-center justify-between">
              <%= unless @sidebar_collapsed do %>
                <div>
                  <h3 class="text-sm font-bold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent uppercase tracking-wider">
                    All Terminals
                  </h3>
                  <p class="text-xs text-gray-500 mt-2">
                    {map_size(@global_terminals)} active terminal(s)
                  </p>
                </div>
              <% end %>
              <button
                phx-click="toggle-sidebar"
                class={[
                  "flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-colors text-gray-400 hover:text-gray-200",
                  if @sidebar_collapsed do
                    "mx-auto"
                  else
                    "flex-shrink-0"
                  end
                ]}
                title={if @sidebar_collapsed, do: "Expand sidebar", else: "Collapse sidebar"}
              >
                <.icon
                  name={if @sidebar_collapsed, do: "hero-chevron-right", else: "hero-chevron-left"}
                  class="w-4 h-4"
                />
              </button>
            </div>
          </div>
        </div>
        
    <!-- Terminals List -->
        <div class="flex-1 overflow-y-auto overflow-x-hidden py-2">
          <%= if map_size(@global_terminals) > 0 do %>
            <%= if @sidebar_collapsed do %>
              <!-- Collapsed view - only show icons -->
              <%= for {tid, terminal} <- @global_terminals do %>
                <div class="mx-2 mb-1 flex justify-center group relative">
                  <.link
                    navigate={~p"/terminals/#{tid}"}
                    class={[
                      "w-8 h-8 rounded-lg flex items-center justify-center transition-all duration-200 relative",
                      tid == @terminal_id &&
                        "bg-gradient-to-br from-emerald-500 to-green-600 shadow-lg shadow-emerald-950/20",
                      (tid != @terminal_id &&
                         (terminal.connected && "bg-gradient-to-br from-emerald-600 to-green-700")) ||
                        "bg-gradient-to-br from-gray-600 to-gray-700",
                      "hover:scale-105"
                    ]}
                    title={terminal.name}
                  >
                    <.icon name="hero-command-line" class="w-4 h-4 text-white" />
                  </.link>
                  <!-- Close button on hover -->
                  <button
                    phx-click="close-terminal"
                    phx-value-terminal-id={tid}
                    class="absolute -top-1 -right-1 w-4 h-4 bg-red-600 hover:bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-200 z-50"
                    title="Close terminal"
                  >
                    <.icon name="hero-x-mark" class="w-3 h-3" />
                  </button>
                  <!-- Tooltip on hover -->
                  <div class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-40">
                    {terminal.name} - {terminal.worktree_branch}
                  </div>
                </div>
              <% end %>
            <% else %>
              <!-- Expanded view - full details -->
              <%= for {tid, terminal} <- @global_terminals do %>
                <div class={[
                  "mx-2 mb-1 rounded-lg group relative transition-all duration-200 flex items-center hover:bg-gray-800/50",
                  tid == @terminal_id &&
                    "bg-gradient-to-r from-emerald-950/30 to-cyan-950/30 shadow-lg shadow-emerald-950/20"
                ]}>
                  <.link
                    navigate={~p"/terminals/#{tid}"}
                    class="flex-1 block pl-4 pr-2 py-3 transition-all duration-200 rounded-l-lg"
                  >
                    <div class="flex items-center space-x-3">
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
                          {terminal.worktree_branch}
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
                  </.link>
                  <button
                    phx-click="close-terminal"
                    phx-value-terminal-id={tid}
                    class="p-2 mr-2 text-gray-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-all duration-200 rounded-lg hover:bg-red-900/20"
                    title="Close terminal"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              <% end %>
            <% end %>
          <% else %>
            <div class="px-4 py-12 text-center">
              <div class="w-16 h-16 rounded-full bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-command-line" class="w-8 h-8 text-gray-500" />
              </div>
              <p class="text-sm font-medium text-gray-400">No active terminals</p>
              <p class="text-xs text-gray-500 mt-2">Create terminals from the dashboard</p>
            </div>
          <% end %>
        </div>
        
    <!-- Bottom navigation -->
        <div class="border-t border-gray-800/50 p-4">
          <%= if @sidebar_collapsed do %>
            <.link
              navigate={get_dashboard_link(@terminal)}
              class="flex items-center justify-center w-8 h-8 mx-auto rounded-lg bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 transition-all duration-200"
              title="Back to Dashboard"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" />
            </.link>
          <% else %>
            <.link
              navigate={get_dashboard_link(@terminal)}
              class="flex items-center justify-center text-sm font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 rounded-lg px-4 py-2 transition-all duration-200"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" />
              <span class="ml-2">Dashboard</span>
            </.link>
          <% end %>
        </div>
      </div>
      
    <!-- Terminal Content -->
      <div class="flex-1 flex flex-col">
        <div class="bg-gray-900/80 backdrop-blur-sm px-6 py-3 border-b border-gray-800/50 flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
                <.icon name="hero-command-line" class="w-4 h-4 text-white" />
              </div>
              <div>
                <h2 class="text-white font-bold">{@terminal.name}</h2>
                <div class="flex items-center gap-2 text-xs">
                  <span class="text-emerald-400">{@terminal.worktree_branch}</span>
                  <span class="text-gray-600">•</span>
                  <span class="text-gray-500 truncate max-w-md">
                    {@terminal.worktree_path}
                  </span>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-1 ml-4">
              <button
                phx-click="open-in-iterm"
                class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-colors cursor-pointer"
                title="Open in iTerm2"
              >
                <svg
                  class="w-4 h-4 text-gray-400 hover:text-gray-200"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
              </button>
              <button
                phx-click="open-in-zed"
                class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-colors cursor-pointer"
                title="Open in Zed"
              >
                <svg
                  class="w-4 h-4 text-gray-400 hover:text-gray-200"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                  />
                </svg>
              </button>
              <.link
                navigate={~p"/git-diff/terminal-#{@terminal_id}"}
                class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-colors"
                title="View git diffs"
              >
                <svg
                  class="w-4 h-4 text-gray-400 hover:text-gray-200"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                  />
                </svg>
              </.link>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2">
              <span class={[
                "inline-block w-2 h-2 rounded-full",
                (@terminal.connected &&
                   "bg-emerald-400 animate-pulse shadow-emerald-400/50 shadow-sm") || "bg-red-500"
              ]}>
              </span>
              <span class={[
                "text-sm font-medium",
                (@terminal.connected && "text-emerald-400") || "text-red-400"
              ]}>
                {if @terminal.connected, do: "Connected", else: "Disconnected"}
              </span>
            </div>
          </div>
        </div>

        <div class="flex-1 relative bg-black">
          <div
            phx-hook="SingleTerminalHook"
            id="terminal-area"
            data-terminal-id={@terminal_id}
            data-session-id={@session_id}
            class="h-full w-full"
          >
            <div id="terminals-container" phx-update="ignore" class="h-full w-full">
              <div id={"terminal-container-#{@terminal_id}"} class="h-full w-full">
                <div id={"terminal-#{@terminal_id}"} class="h-full w-full"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".OpenUrl">
      export default {
        mounted() {
          this.handleEvent("open-url", ({url}) => {
            window.location.href = url
          })
        }
      }
    </script>
    """
  end
end
