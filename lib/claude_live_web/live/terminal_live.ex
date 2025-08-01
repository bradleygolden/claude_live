defmodule ClaudeLiveWeb.TerminalLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(%{"worktree_id" => worktree_id}, _session, socket) do
    worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)
    # Use worktree ID as session ID for persistence
    session_id = "terminal-#{worktree_id}"
    
    socket =
      socket
      |> assign(:session_id, session_id)
      |> assign(:connected, false)
      |> assign(:terminal_data, "")
      |> assign(:worktree, worktree)
      |> assign(:page_title, "Terminal - #{worktree.branch}")
      |> assign(:existing_session, ClaudeLive.Terminal.PtyServer.exists?(session_id))
    
    {:ok, socket}
  end

  @impl true
  def handle_event("connect", %{"cols" => cols, "rows" => rows}, socket) do
    session_id = socket.assigns.session_id
    
    # Check if session already exists
    if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
      # Reuse existing session
      ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())
      
      # Get and replay buffer
      case ClaudeLive.Terminal.PtyServer.get_buffer(session_id) do
        {:ok, buffer} ->
          # Send all buffered output to restore terminal state
          Enum.each(buffer, fn data ->
            send(self(), {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}})
          end)
        _ -> :ok
      end
      
      # Resize to new dimensions
      ClaudeLive.Terminal.PtyServer.resize(session_id, cols, rows)
    else
      # Start new terminal server
      {:ok, _pid} = ClaudeLive.Terminal.Supervisor.start_terminal(session_id)
      
      # Subscribe to terminal events
      ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())
      
      # Spawn shell in worktree directory
      :ok = ClaudeLive.Terminal.PtyServer.spawn_shell(session_id,
        cols: cols,
        rows: rows,
        shell: System.get_env("SHELL", "/bin/bash"),
        cwd: socket.assigns.worktree.path
      )
    end
    
    {:noreply, assign(socket, :connected, true)}
  end

  @impl true
  def handle_event("input", %{"data" => data}, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.PtyServer.write(socket.assigns.session_id, data)
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("resize", %{"cols" => cols, "rows" => rows}, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.PtyServer.resize(socket.assigns.session_id, cols, rows)
    end
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("disconnect", _params, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.Supervisor.stop_terminal(socket.assigns.session_id)
    end
    
    {:noreply, assign(socket, :connected, false)}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, _session_id, {:terminal_data, data}}, socket) do
    {:noreply, push_event(socket, "terminal_output", %{data: data})}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, _session_id, {:terminal_exit, exit_code}}, socket) do
    Logger.info("Terminal exited with code: #{exit_code}")
    {:noreply, assign(socket, :connected, false) |> push_event("terminal_exit", %{code: exit_code})}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, _session_id, {:terminal_closed, _status}}, socket) do
    {:noreply, assign(socket, :connected, false) |> push_event("terminal_closed", %{})}
  end

  @impl true
  def terminate(_reason, socket) do
    # Just unsubscribe, don't kill the terminal
    if socket.assigns[:connected] && socket.assigns[:session_id] do
      ClaudeLive.Terminal.PtyServer.unsubscribe(socket.assigns.session_id, self())
    end
    
    :ok
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 p-4">
      <div class="max-w-6xl mx-auto">
        <div class="bg-gray-800 rounded-lg shadow-xl overflow-hidden">
          <div class="bg-gray-700 px-4 py-2 flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <h2 class="text-white font-semibold">Terminal</h2>
              <span class="text-sm text-gray-400">
                {@worktree.repository.name} / {@worktree.branch}
              </span>
              <%= if @existing_session do %>
                <span class="text-xs bg-blue-600 text-white px-2 py-1 rounded">
                  Restored Session
                </span>
              <% end %>
            </div>
            <div class="flex items-center space-x-4">
              <span class="text-xs text-gray-400">
                {@worktree.path}
              </span>
              <div class="flex items-center space-x-2">
                <span class={[
                  "inline-block w-3 h-3 rounded-full",
                  @connected && "bg-green-500" || "bg-red-500"
                ]}></span>
                <span class="text-sm text-gray-300">
                  <%= if @connected, do: "Connected", else: "Disconnected" %>
                </span>
              </div>
            </div>
          </div>
          
          <div
            id="terminal-container"
            phx-hook="TerminalHook"
            phx-update="ignore"
            class="h-[600px] w-full"
          >
            <div id="terminal" class="h-full w-full"></div>
          </div>
        </div>
        
        <div class="mt-4 flex justify-between">
          <.link
            navigate={~p"/dashboard/#{@worktree.repository_id}"}
            class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition"
          >
            ← Back to Dashboard
          </.link>
          <button
            phx-click="disconnect"
            class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
            :if={@connected}
          >
            Disconnect
          </button>
        </div>
      </div>
    </div>
    """
  end
end