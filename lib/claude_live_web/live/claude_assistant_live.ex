defmodule ClaudeLiveWeb.ClaudeAssistantLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    session_id = "claude-assistant-#{System.unique_integer([:positive])}"

    socket =
      socket
      |> assign(:session_id, session_id)
      |> assign(:connected, false)
      |> assign(:expanded, false)
      # Default height in pixels
      |> assign(:terminal_height, 400)
      |> assign(:fullscreen, false)
      |> assign(:state_loaded, false)

    {:ok, push_event(socket, "load-terminal-state", %{})}
  end

  @impl true
  def handle_event("toggle-expand", _params, socket) do
    expanded = !socket.assigns.expanded
    socket = assign(socket, :expanded, expanded)

    {:noreply,
     push_event(socket, "save-terminal-state", %{
       expanded: expanded,
       height: socket.assigns.terminal_height,
       fullscreen: socket.assigns.fullscreen
     })}
  end

  @impl true
  def handle_event("toggle-fullscreen", _params, socket) do
    fullscreen = !socket.assigns.fullscreen
    socket = assign(socket, :fullscreen, fullscreen)

    {:noreply,
     push_event(socket, "save-terminal-state", %{
       expanded: socket.assigns.expanded,
       height: socket.assigns.terminal_height,
       fullscreen: fullscreen
     })}
  end

  @impl true
  def handle_event("resize", %{"height" => height}, socket) do
    # Clamp height between 200 and 800 pixels
    height = max(200, min(800, height))
    socket = assign(socket, :terminal_height, height)

    {:noreply,
     push_event(socket, "save-terminal-state", %{
       expanded: socket.assigns.expanded,
       height: height,
       fullscreen: socket.assigns.fullscreen
     })}
  end

  @impl true
  def handle_event("restore-state", params, socket) do
    socket =
      socket
      |> assign(:expanded, Map.get(params, "expanded", false))
      |> assign(:terminal_height, Map.get(params, "height", 400))
      |> assign(:fullscreen, Map.get(params, "fullscreen", false))
      |> assign(:state_loaded, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("init", %{"cols" => cols, "rows" => rows}, socket) do
    session_id = socket.assigns.session_id

    if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
      # Terminal already exists, just resize
      ClaudeLive.Terminal.PtyServer.resize(session_id, cols, rows)
      {:noreply, socket}
    else
      # Start new terminal
      case ClaudeLive.Terminal.Supervisor.start_terminal(session_id) do
        {:ok, _pid} ->
          Process.sleep(50)

          try do
            ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())

            ClaudeLive.Terminal.PtyServer.spawn_shell(session_id,
              cols: cols,
              rows: rows,
              shell: System.get_env("SHELL", "/bin/bash"),
              cwd: File.cwd!()
            )

            {:noreply, assign(socket, :connected, true)}
          catch
            :exit, {:timeout, _} ->
              Logger.error("Failed to initialize terminal #{session_id}")
              {:noreply, socket}
          end

        {:error, reason} ->
          Logger.error("Failed to start terminal: #{inspect(reason)}")
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("input", %{"data" => data}, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.PtyServer.write(socket.assigns.session_id, data)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("terminal-resize", %{"cols" => cols, "rows" => rows}, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.PtyServer.resize(socket.assigns.session_id, cols, rows)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, push_event(socket, "output", %{data: data})}
  end

  @impl true
  def handle_info({:terminal_closed, session_id}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, assign(socket, :connected, false)}
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns.connected do
      ClaudeLive.Terminal.PtyServer.kill(socket.assigns.session_id)
    end

    :ok
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="fixed bottom-0 left-0 right-0 z-50"
      id="terminal-state-manager"
      phx-hook="TerminalStateManager"
    >
      <!-- Collapsed bar -->
      <div :if={!@expanded} class="bg-gray-900 border-t border-gray-700">
        <button
          phx-click="toggle-expand"
          class="w-full px-3 py-1 flex items-center justify-between text-gray-400 hover:text-gray-200 transition-colors"
        >
          <div class="flex items-center gap-2 text-xs font-mono">
            <span class={[
              "inline-block w-1.5 h-1.5 rounded-full",
              (@connected && "bg-green-500") || "bg-gray-600"
            ]} />
            <span>Terminal</span>
          </div>
          <.icon name="hero-chevron-up" class="w-3 h-3" />
        </button>
      </div>
      
    <!-- Expanded terminal -->
      <div
        :if={@expanded}
        class={[
          "bg-gray-900 border-t border-gray-700 flex flex-col",
          @fullscreen && "fixed inset-0 z-[100]"
        ]}
        style={(!@fullscreen && "height: #{@terminal_height}px") || ""}
      >
        <!-- Resize handle (only show when not fullscreen) -->
        <div
          :if={!@fullscreen}
          id="terminal-resize-handle"
          class="h-1 bg-gray-800 hover:bg-gray-700 cursor-ns-resize"
          phx-hook="ResizeHandle"
        >
        </div>
        
    <!-- Header -->
        <div class="bg-gray-900 px-3 py-1 flex items-center justify-between border-b border-gray-800">
          <div class="flex items-center gap-2 text-xs font-mono text-gray-400">
            <span class={[
              "inline-block w-1.5 h-1.5 rounded-full",
              (@connected && "bg-green-500") || "bg-gray-600"
            ]} />
            <span>Terminal</span>
          </div>

          <div class="flex items-center gap-2">
            <button
              phx-click="toggle-fullscreen"
              class="text-gray-500 hover:text-gray-300 transition-colors"
              title={(@fullscreen && "Exit fullscreen") || "Fullscreen"}
            >
              <.icon
                name={(@fullscreen && "hero-arrows-pointing-in") || "hero-arrows-pointing-out"}
                class="w-3 h-3"
              />
            </button>
            <button
              phx-click="toggle-expand"
              class="text-gray-500 hover:text-gray-300 transition-colors"
            >
              <.icon name="hero-chevron-down" class="w-3 h-3" />
            </button>
          </div>
        </div>
        
    <!-- Terminal container -->
        <div
          id="claude-assistant-terminal"
          phx-hook="ClaudeAssistantTerminal"
          class="flex-1 overflow-hidden bg-black"
          phx-update="ignore"
        >
        </div>
      </div>
    </div>
    """
  end
end
