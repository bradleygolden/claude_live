defmodule ClaudeLiveWeb.TerminalLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(%{"worktree_id" => worktree_id}, _session, socket) do
    worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)
    # Use worktree ID as session ID for persistence
    session_id = "terminal-#{worktree_id}"

    # Load all worktrees for the repository to show in sidebar
    repository = Ash.get!(ClaudeLive.Claude.Repository, worktree.repository_id, load: :worktrees)
    worktrees = repository.worktrees

    socket =
      socket
      |> assign(:session_id, session_id)
      |> assign(:connected, false)
      |> assign(:terminal_data, "")
      |> assign(:worktree, worktree)
      |> assign(:worktrees, worktrees)
      |> assign(:repository, repository)
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

        _ ->
          :ok
      end

      # Resize to new dimensions
      ClaudeLive.Terminal.PtyServer.resize(session_id, cols, rows)
    else
      # Start new terminal server
      {:ok, _pid} = ClaudeLive.Terminal.Supervisor.start_terminal(session_id)

      # Subscribe to terminal events
      ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())

      # Spawn shell in worktree directory
      :ok =
        ClaudeLive.Terminal.PtyServer.spawn_shell(session_id,
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
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, _session_id, {:terminal_exit, exit_code}},
        socket
      ) do
    Logger.info("Terminal exited with code: #{exit_code}")

    {:noreply,
     assign(socket, :connected, false) |> push_event("terminal_exit", %{code: exit_code})}
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, _session_id, {:terminal_closed, _status}},
        socket
      ) do
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
    <script :type={Phoenix.LiveView.ColocatedHook} name=".TerminalHook">
      export default {
        mounted() {
          const Terminal = window.Terminal;
          const FitAddon = window.FitAddon?.FitAddon || window.FitAddon;
          const WebLinksAddon = window.WebLinksAddon?.WebLinksAddon || window.WebLinksAddon;
          
          if (!Terminal) {
            console.error("Terminal is not defined. Make sure xterm.js is loaded properly.");
            return;
          }
          
          this._initTerminal(Terminal, FitAddon, WebLinksAddon);
        },
        
        _initTerminal(Terminal, FitAddon, WebLinksAddon) {
          this.terminal = new Terminal({
            cursorBlink: true,
            fontSize: 14,
            fontFamily: 'Menlo, Monaco, "Courier New", monospace',
            theme: {
              background: '#1a1a1a',
              foreground: '#d4d4d4',
              cursor: '#d4d4d4',
              black: '#000000',
              red: '#cd3131',
              green: '#0dbc79',
              yellow: '#e5e510',
              blue: '#2472c8',
              magenta: '#bc3fbc',
              cyan: '#11a8cd',
              white: '#e5e5e5',
              brightBlack: '#666666',
              brightRed: '#f14c4c',
              brightGreen: '#23d18b',
              brightYellow: '#f5f543',
              brightBlue: '#3b8eea',
              brightMagenta: '#d670d6',
              brightCyan: '#29b8db',
              brightWhite: '#e5e5e5'
            }
          });

          // Add addons
          this.fitAddon = new FitAddon();
          this.terminal.loadAddon(this.fitAddon);
          this.terminal.loadAddon(new WebLinksAddon());

          const terminalElement = document.getElementById('terminal');
          
          if (!terminalElement) {
            console.error("Terminal element not found!");
            return;
          }
          
          this.terminal.open(terminalElement);
          this.fitAddon.fit();
          
          setTimeout(() => {
            this.terminal.focus();
          }, 100);
          
          this.el.addEventListener('click', () => {
            this.terminal.focus();
          });

          const cols = this.terminal.cols;
          const rows = this.terminal.rows;

          this.pushEvent("connect", { cols, rows });

          this.terminal.onData(data => {
            this.pushEvent("input", { data });
          });

          this.resizeObserver = new ResizeObserver(() => {
            this.fitAddon.fit();
            const cols = this.terminal.cols;
            const rows = this.terminal.rows;
            this.pushEvent("resize", { cols, rows });
          });
          this.resizeObserver.observe(this.el);

          this.handleEvent("terminal_output", ({ data }) => {
            this.terminal.write(data);
          });

          this.handleEvent("terminal_exit", ({ code }) => {
            this.terminal.write(`\\r\\n[Process exited with code ${code}]\\r\\n`);
          });

          this.handleEvent("terminal_closed", () => {
            this.terminal.write('\\r\\n[Terminal closed]\\r\\n');
          });
        },

        destroyed() {
          if (this.resizeObserver) {
            this.resizeObserver.disconnect();
          }
          if (this.terminal) {
            this.terminal.dispose();
          }
        }
      }
    </script>

    <div class="h-screen bg-gray-900 flex">
      <!-- Sidebar for worktree switching -->
      <div class="w-56 bg-gray-800 border-r border-gray-700 flex flex-col">
        <div class="p-4 border-b border-gray-700">
          <h3 class="text-sm font-semibold text-gray-400 uppercase tracking-wider">
            Workspaces
          </h3>
          <p class="text-xs text-gray-500 mt-1">{@repository.name}</p>
        </div>

        <div class="flex-1 overflow-y-auto">
          <%= for wt <- @worktrees do %>
            <.link
              navigate={~p"/terminal/#{wt.id}"}
              class={[
                "block px-4 py-3 hover:bg-gray-700 transition-colors border-l-4",
                if(wt.id == @worktree.id,
                  do: "bg-gray-700 border-blue-500",
                  else: "border-transparent hover:border-gray-600"
                )
              ]}
            >
              <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-sm text-gray-200 truncate">
                    {wt.branch}
                  </div>
                  <%= if ClaudeLive.Terminal.PtyServer.exists?("terminal-#{wt.id}") do %>
                    <div class="flex items-center mt-1">
                      <span class="inline-block w-2 h-2 rounded-full bg-green-500 mr-1"></span>
                      <span class="text-xs text-gray-400">Active</span>
                    </div>
                  <% else %>
                    <span class="text-xs text-gray-500">No session</span>
                  <% end %>
                </div>
                <%= if wt.id == @worktree.id do %>
                  <.icon name="hero-chevron-right" class="w-4 h-4 text-gray-400" />
                <% end %>
              </div>
            </.link>
          <% end %>
        </div>

        <div class="p-3 border-t border-gray-700">
          <.link
            navigate={~p"/dashboard/#{@worktree.repository_id}"}
            class="flex items-center text-sm text-gray-400 hover:text-gray-200 transition"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Dashboard
          </.link>
        </div>
      </div>
      
    <!-- Main terminal area -->
      <div class="flex-1 flex flex-col">
        <div class="flex-1 flex flex-col p-2">
          <div class="bg-gray-800 rounded-lg shadow-xl overflow-hidden flex-1 flex flex-col">
            <div class="bg-gray-700 px-4 py-2 flex items-center justify-between flex-shrink-0">
              <div class="flex items-center space-x-3">
                <h2 class="text-white font-semibold">Terminal</h2>
                <span class="text-sm text-gray-400">
                  {@worktree.branch}
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
                    (@connected && "bg-green-500") || "bg-red-500"
                  ]}>
                  </span>
                  <span class="text-sm text-gray-300">
                    {if @connected, do: "Connected", else: "Disconnected"}
                  </span>
                </div>
              </div>
            </div>

            <div
              id="terminal-container"
              phx-hook=".TerminalHook"
              phx-update="ignore"
              class="flex-1 w-full"
            >
              <div id="terminal" class="h-full w-full"></div>
            </div>
          </div>

          <div class="mt-2 flex justify-end flex-shrink-0">
            <button
              :if={@connected}
              phx-click="disconnect"
              class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
            >
              Disconnect
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
