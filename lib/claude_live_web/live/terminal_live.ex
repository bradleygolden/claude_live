defmodule ClaudeLiveWeb.TerminalLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(%{"worktree_id" => worktree_id}, _session, socket) do
    worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)
    repository = Ash.get!(ClaudeLive.Claude.Repository, worktree.repository_id, load: :worktrees)
    worktrees = repository.worktrees

    socket =
      socket
      |> assign(:worktree, worktree)
      |> assign(:worktrees, worktrees)
      |> assign(:repository, repository)
      |> assign(:page_title, "Terminal - #{worktree.branch}")
      |> assign(:terminals, %{})
      |> assign(:active_terminal_id, nil)
      |> assign(:show_active_only, false)
      |> load_all_terminals()

    {:ok, socket}
  end

  @impl true
  def handle_event("create_terminal", %{"worktree_id" => wt_id}, socket) do
    terminal_id = generate_terminal_id(wt_id)
    worktree = Enum.find(socket.assigns.worktrees, &(&1.id == wt_id))

    terminal = %{
      id: terminal_id,
      worktree_id: wt_id,
      worktree_branch: worktree.branch,
      worktree_path: worktree.path,
      session_id: "terminal-#{terminal_id}",
      connected: false,
      terminal_data: "",
      name: "Terminal #{count_worktree_terminals(socket.assigns.terminals, wt_id) + 1}"
    }

    terminals = Map.put(socket.assigns.terminals, terminal_id, terminal)

    {:noreply,
     socket
     |> assign(:terminals, terminals)
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
  def handle_event("toggle_active_filter", _params, socket) do
    {:noreply, assign(socket, :show_active_only, !socket.assigns.show_active_only)}
  end

  @impl true
  def handle_event("rename_terminal", %{"terminal_id" => terminal_id, "name" => name}, socket) do
    terminals = put_in(socket.assigns.terminals[terminal_id].name, name)
    {:noreply, assign(socket, :terminals, terminals)}
  end

  @impl true
  def handle_event("close_terminal", %{"terminal_id" => terminal_id}, socket) do
    terminal = socket.assigns.terminals[terminal_id]

    if terminal.connected do
      ClaudeLive.Terminal.PtyServer.unsubscribe(terminal.session_id, self())
      ClaudeLive.Terminal.Supervisor.stop_terminal(terminal.session_id)
    end

    terminals = Map.delete(socket.assigns.terminals, terminal_id)

    # Select a new active terminal if we closed the active one
    new_active =
      if socket.assigns.active_terminal_id == terminal_id do
        case Map.keys(terminals) do
          [] -> nil
          keys -> List.first(keys)
        end
      else
        socket.assigns.active_terminal_id
      end

    socket =
      socket
      |> assign(:terminals, terminals)
      |> assign(:active_terminal_id, new_active)

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
    terminal = socket.assigns.terminals[terminal_id]
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

    terminals = put_in(socket.assigns.terminals[terminal_id].connected, true)
    {:noreply, assign(socket, :terminals, terminals)}
  end

  @impl true
  def handle_event("input", %{"data" => data, "terminal_id" => terminal_id}, socket) do
    terminal = socket.assigns.terminals[terminal_id]

    if terminal && terminal.connected do
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
    terminal = socket.assigns.terminals[terminal_id]

    if terminal && terminal.connected do
      ClaudeLive.Terminal.PtyServer.resize(terminal.session_id, cols, rows)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("disconnect", _params, socket) do
    # Disconnect all terminals in current worktree
    socket.assigns.terminals
    |> Enum.filter(fn {_id, t} -> t.worktree_id == socket.assigns.worktree.id && t.connected end)
    |> Enum.each(fn {_id, terminal} ->
      ClaudeLive.Terminal.Supervisor.stop_terminal(terminal.session_id)
    end)

    terminals =
      socket.assigns.terminals
      |> Enum.map(fn {id, t} ->
        if t.worktree_id == socket.assigns.worktree.id do
          {id, %{t | connected: false}}
        else
          {id, t}
        end
      end)
      |> Map.new()

    {:noreply, assign(socket, :terminals, terminals)}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket) do
    terminal_id = find_terminal_by_session(socket.assigns.terminals, session_id)

    if terminal_id do
      {:noreply, push_event(socket, "terminal_output", %{data: data, terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_exit, exit_code}},
        socket
      ) do
    terminal_id = find_terminal_by_session(socket.assigns.terminals, session_id)

    if terminal_id do
      Logger.info("Terminal #{terminal_id} exited with code: #{exit_code}")
      terminals = put_in(socket.assigns.terminals[terminal_id].connected, false)

      {:noreply,
       socket
       |> assign(:terminals, terminals)
       |> push_event("terminal_exit", %{code: exit_code, terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_closed, _status}},
        socket
      ) do
    terminal_id = find_terminal_by_session(socket.assigns.terminals, session_id)

    if terminal_id do
      terminals = put_in(socket.assigns.terminals[terminal_id].connected, false)

      {:noreply,
       socket
       |> assign(:terminals, terminals)
       |> push_event("terminal_closed", %{terminal_id: terminal_id})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    # Unsubscribe from all connected terminals
    socket.assigns.terminals
    |> Enum.filter(fn {_id, terminal} -> terminal.connected end)
    |> Enum.each(fn {_id, terminal} ->
      ClaudeLive.Terminal.PtyServer.unsubscribe(terminal.session_id, self())
    end)

    :ok
  end

  # Private helpers

  defp load_all_terminals(socket) do
    # Load existing terminal sessions for all worktrees
    terminals =
      socket.assigns.worktrees
      |> Enum.flat_map(fn worktree ->
        # Check for existing sessions using the old format
        session_id = "terminal-#{worktree.id}"

        if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
          terminal_id = "#{worktree.id}-legacy"

          [
            {terminal_id,
             %{
               id: terminal_id,
               worktree_id: worktree.id,
               worktree_branch: worktree.branch,
               worktree_path: worktree.path,
               session_id: session_id,
               connected: false,
               terminal_data: "",
               name: "Terminal 1"
             }}
          ]
        else
          []
        end
      end)
      |> Map.new()

    # Set active terminal to the first one for current worktree if any
    active_id =
      terminals
      |> Enum.find(fn {_id, t} -> t.worktree_id == socket.assigns.worktree.id end)
      |> case do
        {id, _} -> id
        nil -> nil
      end

    socket
    |> assign(:terminals, terminals)
    |> assign(:active_terminal_id, active_id)
  end

  defp generate_terminal_id(worktree_id) do
    timestamp = System.system_time(:millisecond)
    "#{worktree_id}-#{timestamp}"
  end

  defp count_worktree_terminals(terminals, worktree_id) do
    terminals
    |> Enum.count(fn {_id, terminal} -> terminal.worktree_id == worktree_id end)
  end

  defp get_worktree_terminals(terminals, worktree_id) do
    terminals
    |> Enum.filter(fn {_id, terminal} -> terminal.worktree_id == worktree_id end)
    |> Enum.sort_by(fn {_id, terminal} -> terminal.name end)
  end

  defp get_filtered_worktree_terminals(terminals, worktree_id, show_active_only) do
    terminals
    |> get_worktree_terminals(worktree_id)
    |> then(fn terminals ->
      if show_active_only do
        Enum.filter(terminals, fn {_id, terminal} -> terminal.connected end)
      else
        terminals
      end
    end)
  end

  defp find_terminal_by_session(terminals, session_id) do
    terminals
    |> Enum.find(fn {_id, terminal} -> terminal.session_id == session_id end)
    |> case do
      {id, _terminal} -> id
      nil -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <script :type={Phoenix.LiveView.ColocatedHook} name=".TerminalHook">
      export default {
        terminals: {},
        activeTerminalId: null,
        
        mounted() {
          this.handleEvent("terminal_output", ({ data, terminal_id }) => {
            if (this.terminals[terminal_id]) {
              this.terminals[terminal_id].write(data);
            }
          });
          
          this.handleEvent("terminal_exit", ({ code, terminal_id }) => {
            if (this.terminals[terminal_id]) {
              this.terminals[terminal_id].write(`\\r\\n[Process exited with code ${code}]\\r\\n`);
            }
          });
          
          this.handleEvent("terminal_closed", ({ terminal_id }) => {
            if (this.terminals[terminal_id]) {
              this.terminals[terminal_id].write('\\r\\n[Terminal closed]\\r\\n');
            }
          });
          
          this.handleEvent("switch_terminal", ({ terminal_id }) => {
            this.switchTerminal(terminal_id);
          });
          
          // Initialize first terminal if exists
          const firstTerminal = this.el.querySelector('[data-terminal-id]');
          if (firstTerminal) {
            const terminalId = firstTerminal.dataset.terminalId;
            setTimeout(() => this.switchTerminal(terminalId), 100);
          }
        },
        
        initTerminal(terminalId) {
          const Terminal = window.Terminal;
          const FitAddon = window.FitAddon?.FitAddon || window.FitAddon;
          const WebLinksAddon = window.WebLinksAddon?.WebLinksAddon || window.WebLinksAddon;
          
          if (!Terminal) {
            console.error("Terminal is not defined");
            return;
          }
          
          const container = document.getElementById(`terminal-${terminalId}`);
          if (!container) {
            console.error(`Terminal container not found for ${terminalId}`);
            return;
          }
          
          // Clean up existing terminal if it exists
          if (this.terminals[terminalId]) {
            if (this.terminals[terminalId].resizeObserver) {
              this.terminals[terminalId].resizeObserver.disconnect();
            }
            this.terminals[terminalId].dispose();
            delete this.terminals[terminalId];
          }
          
          const terminal = new Terminal({
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
          
          const fitAddon = new FitAddon();
          terminal.loadAddon(fitAddon);
          terminal.loadAddon(new WebLinksAddon());
          
          terminal.open(container);
          fitAddon.fit();
          
          this.terminals[terminalId] = terminal;
          this.terminals[terminalId].fitAddon = fitAddon;
          
          // Setup event handlers
          terminal.onData(data => {
            this.pushEvent("input", { data, terminal_id: terminalId });
          });
          
          // Setup resize observer
          const resizeObserver = new ResizeObserver(() => {
            if (this.terminals[terminalId] && this.terminals[terminalId].fitAddon) {
              this.terminals[terminalId].fitAddon.fit();
              const cols = terminal.cols;
              const rows = terminal.rows;
              this.pushEvent("resize", { cols, rows, terminal_id: terminalId });
            }
          });
          resizeObserver.observe(container);
          this.terminals[terminalId].resizeObserver = resizeObserver;
          
          // Connect to backend
          const cols = terminal.cols;
          const rows = terminal.rows;
          this.pushEvent("connect", { cols, rows, terminal_id: terminalId });
          
          // Focus the terminal
          setTimeout(() => terminal.focus(), 100);
        },
        
        switchTerminal(terminalId) {
          // Hide all terminals
          document.querySelectorAll('.terminal-container').forEach(el => {
            el.style.display = 'none';
          });
          
          // Show selected terminal
          const container = document.getElementById(`terminal-container-${terminalId}`);
          if (container) {
            container.style.display = 'block';
            
            // Initialize if not already done
            if (!this.terminals[terminalId]) {
              this.initTerminal(terminalId);
            } else {
              // Refit and focus
              if (this.terminals[terminalId].fitAddon) {
                this.terminals[terminalId].fitAddon.fit();
              }
              this.terminals[terminalId].focus();
            }
          }
          
          this.activeTerminalId = terminalId;
        },
        
        destroyed() {
          // Clean up all terminals
          Object.keys(this.terminals).forEach(terminalId => {
            if (this.terminals[terminalId]) {
              if (this.terminals[terminalId].resizeObserver) {
                this.terminals[terminalId].resizeObserver.disconnect();
              }
              this.terminals[terminalId].dispose();
            }
          });
          this.terminals = {};
        }
      }
    </script>

    <div class="h-screen bg-gray-900 flex">
      <!-- Sidebar for workspace and terminal switching -->
      <div class="w-64 bg-gray-800 border-r border-gray-700 flex flex-col">
        <div class="p-4 border-b border-gray-700">
          <h3 class="text-sm font-semibold text-gray-400 uppercase tracking-wider">
            Workspaces & Terminals
          </h3>
          <p class="text-xs text-gray-500 mt-1">{@repository.name}</p>
          <button
            phx-click="toggle_active_filter"
            class={[
              "mt-2 px-3 py-1 text-xs rounded transition w-full",
              (@show_active_only && "bg-blue-600 text-white hover:bg-blue-700") ||
                "bg-gray-700 text-gray-300 hover:bg-gray-600"
            ]}
          >
            <%= if @show_active_only do %>
              <.icon name="hero-funnel-solid" class="w-3 h-3 inline mr-1" /> Showing Active Only
            <% else %>
              <.icon name="hero-funnel" class="w-3 h-3 inline mr-1" /> Show Active Only
            <% end %>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto">
          <%= for wt <- @worktrees do %>
            <% worktree_terminals =
              get_filtered_worktree_terminals(@terminals, wt.id, @show_active_only) %>
            <div class="border-b border-gray-700">
              <div class={[
                "px-4 py-3 flex items-center justify-between",
                wt.id == @worktree.id && "bg-gray-750"
              ]}>
                <div class="flex items-center space-x-2">
                  <.icon name="hero-folder" class="w-4 h-4 text-gray-400" />
                  <span class={[
                    "text-sm font-medium",
                    (wt.id == @worktree.id && "text-blue-400") || "text-gray-200"
                  ]}>
                    {wt.branch}
                  </span>
                </div>
                <button
                  phx-click="create_terminal"
                  phx-value-worktree_id={wt.id}
                  class="text-gray-400 hover:text-gray-200 transition"
                  title="New Terminal"
                >
                  <.icon name="hero-plus-circle" class="w-4 h-4" />
                </button>
              </div>

              <%= if length(worktree_terminals) > 0 do %>
                <div class="bg-gray-850">
                  <%= for {terminal_id, terminal} <- worktree_terminals do %>
                    <button
                      phx-click="switch_terminal"
                      phx-value-terminal_id={terminal_id}
                      data-terminal-id={terminal_id}
                      class={[
                        "w-full px-6 py-2 text-left hover:bg-gray-700 transition flex items-center justify-between group",
                        terminal_id == @active_terminal_id && "bg-gray-700"
                      ]}
                    >
                      <div class="flex items-center space-x-2">
                        <.icon name="hero-command-line" class="w-3 h-3 text-gray-500" />
                        <span class="text-sm text-gray-300">{terminal.name}</span>
                        <%= if terminal.connected do %>
                          <span class="w-2 h-2 rounded-full bg-green-500"></span>
                        <% end %>
                      </div>
                      <button
                        phx-click="close_terminal"
                        phx-value-terminal_id={terminal_id}
                        class="opacity-0 group-hover:opacity-100 transition"
                        onclick="event.stopPropagation()"
                      >
                        <.icon name="hero-x-mark" class="w-3 h-3 text-gray-500 hover:text-red-400" />
                      </button>
                    </button>
                  <% end %>
                </div>
              <% else %>
                <div class="px-6 py-2 text-xs text-gray-500">
                  No terminals
                </div>
              <% end %>
            </div>
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
      
    <!-- Terminal area -->
      <div class="flex-1 flex flex-col">
        <%= if @active_terminal_id && @terminals[@active_terminal_id] do %>
          <% active_terminal = @terminals[@active_terminal_id] %>
          <div class="bg-gray-800 px-4 py-2 border-b border-gray-700 flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <h2 class="text-white font-semibold">{active_terminal.name}</h2>
              <span class="text-sm text-gray-400">
                {active_terminal.worktree_branch}
              </span>
              <span class="text-xs text-gray-500">
                {active_terminal.worktree_path}
              </span>
            </div>
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-2">
                <span class={[
                  "inline-block w-3 h-3 rounded-full",
                  (active_terminal.connected && "bg-green-500") || "bg-red-500"
                ]}>
                </span>
                <span class="text-sm text-gray-300">
                  {if active_terminal.connected, do: "Connected", else: "Disconnected"}
                </span>
              </div>
              <%= if active_terminal.connected do %>
                <button
                  phx-click="disconnect"
                  class="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700 transition"
                >
                  Disconnect All
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <div
          class="flex-1 relative bg-black"
          phx-hook=".TerminalHook"
          phx-update="ignore"
          id="terminal-area"
        >
          <%= if map_size(@terminals) == 0 do %>
            <div class="absolute inset-0 flex items-center justify-center">
              <div class="text-center">
                <.icon name="hero-command-line" class="w-12 h-12 text-gray-600 mx-auto mb-4" />
                <p class="text-gray-400">No terminals open</p>
                <p class="text-sm text-gray-500 mt-2">
                  Click the + button next to a workspace to create a terminal
                </p>
              </div>
            </div>
          <% else %>
            <%= for {terminal_id, _terminal} <- @terminals do %>
              <div
                id={"terminal-container-#{terminal_id}"}
                class="terminal-container absolute inset-0"
                style={"display: #{if terminal_id == @active_terminal_id, do: "block", else: "none"}"}
              >
                <div id={"terminal-#{terminal_id}"} class="h-full w-full"></div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
