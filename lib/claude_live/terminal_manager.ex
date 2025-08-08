defmodule ClaudeLive.TerminalManager do
  @moduledoc """
  Global terminal state manager that keeps track of all terminals across all repositories.
  This GenServer maintains the authoritative state of terminals and broadcasts updates via PubSub.
  """
  use GenServer
  require Logger

  @topic "terminals"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Subscribe to terminal updates
  """
  def subscribe do
    Phoenix.PubSub.subscribe(ClaudeLive.PubSub, @topic)
  end

  @doc """
  Get all terminals
  """
  def list_terminals do
    GenServer.call(__MODULE__, :list_terminals)
  end

  @doc """
  Get terminals for a specific worktree
  """
  def list_worktree_terminals(worktree_id) do
    GenServer.call(__MODULE__, {:list_worktree_terminals, worktree_id})
  end

  @doc """
  Create or update a terminal
  """
  def upsert_terminal(terminal_id, terminal_data) do
    GenServer.call(__MODULE__, {:upsert_terminal, terminal_id, terminal_data})
  end

  @doc """
  Get a specific terminal by ID
  """
  def get_terminal(terminal_id) do
    GenServer.call(__MODULE__, {:get_terminal, terminal_id})
  end

  @doc """
  Delete a terminal
  """
  def delete_terminal(terminal_id) do
    GenServer.call(__MODULE__, {:delete_terminal, terminal_id})
  end

  @doc """
  Update terminal connection status
  """
  def update_terminal_status(terminal_id, connected) do
    GenServer.call(__MODULE__, {:update_status, terminal_id, connected})
  end

  @doc """
  Mark terminal as active (selected in the UI)
  """
  def set_active_terminal(terminal_id, session_id) do
    GenServer.call(__MODULE__, {:set_active, terminal_id, session_id})
  end

  # Server Callbacks

  @impl true
  def init(_) do
    terminals = load_existing_terminals()
    {:ok, %{terminals: terminals, active_terminals: %{}}}
  end

  @impl true
  def handle_call(:list_terminals, _from, state) do
    {:reply, state.terminals, state}
  end

  @impl true
  def handle_call({:list_worktree_terminals, worktree_id}, _from, state) do
    terminals =
      state.terminals
      |> Enum.filter(fn {_id, terminal} -> terminal.worktree_id == worktree_id end)
      |> Map.new()

    {:reply, terminals, state}
  end

  @impl true
  def handle_call({:get_terminal, terminal_id}, _from, state) do
    {:reply, Map.get(state.terminals, terminal_id), state}
  end

  @impl true
  def handle_call({:upsert_terminal, terminal_id, terminal_data}, _from, state) do
    updated_terminals = Map.put(state.terminals, terminal_id, terminal_data)
    new_state = %{state | terminals: updated_terminals}
    broadcast(:terminal_updated, {terminal_id, terminal_data})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:delete_terminal, terminal_id}, _from, state) do
    {terminal, updated_terminals} = Map.pop(state.terminals, terminal_id)

    if terminal do
      # Try to stop the terminal, but don't block if it's unresponsive
      if terminal[:session_id] do
        Task.start(fn ->
          try do
            ClaudeLive.Terminal.Supervisor.stop_terminal(terminal.session_id)
          catch
            :exit, _ -> :ok
            :error, _ -> :ok
          end
        end)
      end

      updated_active =
        Map.reject(state.active_terminals, fn {_session, tid} -> tid == terminal_id end)

      new_state = %{state | terminals: updated_terminals, active_terminals: updated_active}
      broadcast(:terminal_deleted, terminal_id)

      {:reply, :ok, new_state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:update_status, terminal_id, connected}, _from, state) do
    case Map.get(state.terminals, terminal_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      terminal ->
        updated_terminal = Map.put(terminal, :connected, connected)
        updated_terminals = Map.put(state.terminals, terminal_id, updated_terminal)
        new_state = %{state | terminals: updated_terminals}
        broadcast(:terminal_status_updated, {terminal_id, connected})

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:set_active, terminal_id, session_id}, _from, state) do
    updated_active = Map.put(state.active_terminals, session_id, terminal_id)
    new_state = %{state | active_terminals: updated_active}
    broadcast(:terminal_activated, {terminal_id, session_id})

    {:reply, :ok, new_state}
  end

  # Private Functions

  defp load_existing_terminals do
    repositories = ClaudeLive.Claude.Repository |> Ash.read!(load: :worktrees)

    repositories
    |> Enum.flat_map(& &1.worktrees)
    |> Enum.flat_map(fn worktree ->
      find_existing_sessions_for_worktree(worktree)
    end)
    |> Map.new(fn terminal -> {terminal.id, terminal} end)
  end

  defp find_existing_sessions_for_worktree(worktree) do
    potential_sessions =
      for i <- 1..10 do
        "terminal-#{worktree.id}-#{i}"
      end

    potential_sessions = ["terminal-#{worktree.id}" | potential_sessions]

    potential_sessions
    |> Enum.filter(&ClaudeLive.Terminal.PtyServer.exists?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {session_id, index} ->
      terminal_number = extract_terminal_number(session_id) || index
      terminal_id = "#{worktree.id}-#{terminal_number}"

      %{
        id: terminal_id,
        worktree_id: worktree.id,
        worktree_branch: worktree.branch,
        worktree_path: worktree.path,
        repository_id: worktree.repository_id,
        session_id: session_id,
        connected: true,
        name: "Terminal #{terminal_number}"
      }
    end)
  end

  defp extract_terminal_number(session_id) do
    case String.split(session_id, "-") do
      parts when length(parts) >= 3 ->
        case Integer.parse(List.last(parts)) do
          {num, ""} -> num
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp broadcast(event, data) do
    Phoenix.PubSub.broadcast(ClaudeLive.PubSub, @topic, {event, data})
  end
end
