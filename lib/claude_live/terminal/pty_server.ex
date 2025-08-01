defmodule ClaudeLive.Terminal.PtyServer do
  use GenServer
  require Logger

  @node_script Path.join(:code.priv_dir(:claude_live), "terminal/pty_bridge.js")

  defstruct [:port, :session_id, :subscribers, :output_buffer, :max_buffer_size]

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(session_id))
  end

  def spawn_shell(session_id, opts \\ []) do
    GenServer.call(via_tuple(session_id), {:spawn_shell, opts})
  end

  def write(session_id, data) do
    GenServer.cast(via_tuple(session_id), {:write, data})
  end

  def resize(session_id, cols, rows) do
    GenServer.cast(via_tuple(session_id), {:resize, cols, rows})
  end

  def subscribe(session_id, pid) do
    GenServer.call(via_tuple(session_id), {:subscribe, pid})
  end

  def unsubscribe(session_id, pid) do
    GenServer.cast(via_tuple(session_id), {:unsubscribe, pid})
  end

  def kill(session_id) do
    GenServer.stop(via_tuple(session_id))
  end

  def get_buffer(session_id) do
    GenServer.call(via_tuple(session_id), :get_buffer)
  end

  def exists?(session_id) do
    case Registry.lookup(ClaudeLive.Terminal.Registry, session_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  # Callbacks

  @impl true
  def init(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    
    port = Port.open({:spawn_executable, node_path()}, [
      :binary,
      :exit_status,
      line: 65536,
      args: [@node_script]
    ])
    
    state = %__MODULE__{
      port: port,
      session_id: session_id,
      subscribers: MapSet.new(),
      output_buffer: [],
      max_buffer_size: 10_000  # Store last 10k lines
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:spawn_shell, opts}, _from, state) do
    command = %{
      type: "spawn",
      shell: opts[:shell],
      cols: opts[:cols] || 80,
      rows: opts[:rows] || 24,
      cwd: opts[:cwd],
      env: opts[:env] || %{}
    }
    
    send_command(state.port, command)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    Process.monitor(pid)
    new_state = %{state | subscribers: MapSet.put(state.subscribers, pid)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_buffer, _from, state) do
    {:reply, {:ok, state.output_buffer}, state}
  end

  @impl true
  def handle_cast({:write, data}, state) do
    command = %{
      type: "write",
      data: Base.encode64(data)
    }
    
    send_command(state.port, command)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:resize, cols, rows}, state) do
    command = %{
      type: "resize",
      cols: cols,
      rows: rows
    }
    
    send_command(state.port, command)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:unsubscribe, pid}, state) do
    new_state = %{state | subscribers: MapSet.delete(state.subscribers, pid)}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({port, {:data, {:eol, line}}}, %{port: port} = state) do
    state = case Jason.decode(line) do
      {:ok, %{"type" => "data", "data" => data}} ->
        decoded = Base.decode64!(data)
        broadcast_to_subscribers(state, {:terminal_data, decoded})
        
        # Store in buffer
        new_buffer = add_to_buffer(state.output_buffer, decoded, state.max_buffer_size)
        %{state | output_buffer: new_buffer}
        
      {:ok, %{"type" => "exit", "exitCode" => exit_code}} ->
        broadcast_to_subscribers(state, {:terminal_exit, exit_code})
        state
        
      {:ok, %{"type" => "spawned", "pid" => pid}} ->
        Logger.debug("Terminal spawned with PID: #{pid}")
        state
        
      {:error, _} ->
        Logger.error("Failed to decode message from terminal: #{line}")
        state
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Terminal port exited with status: #{status}")
    broadcast_to_subscribers(state, {:terminal_closed, status})
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_state = %{state | subscribers: MapSet.delete(state.subscribers, pid)}
    {:noreply, new_state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.port do
      send_command(state.port, %{type: "kill"})
      Port.close(state.port)
    end
    :ok
  end

  # Private functions

  defp via_tuple(session_id) do
    {:via, Registry, {ClaudeLive.Terminal.Registry, session_id}}
  end

  defp node_path do
    System.find_executable("node") || raise "Node.js not found in PATH"
  end

  defp send_command(port, command) do
    json = Jason.encode!(command)
    Port.command(port, json <> "\n")
  end

  defp broadcast_to_subscribers(state, message) do
    Enum.each(state.subscribers, fn pid ->
      send(pid, {__MODULE__, state.session_id, message})
    end)
  end

  defp add_to_buffer(buffer, data, max_size) do
    new_buffer = buffer ++ [data]
    if length(new_buffer) > max_size do
      Enum.drop(new_buffer, length(new_buffer) - max_size)
    else
      new_buffer
    end
  end
end