defmodule ClaudeLive.Terminal.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_terminal(session_id, opts \\ []) do
    spec = {ClaudeLive.Terminal.PtyServer, Keyword.put(opts, :session_id, session_id)}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_terminal(session_id) do
    case Registry.lookup(ClaudeLive.Terminal.Registry, session_id) do
      [{pid, _}] ->
        # Try graceful termination first, then force kill if needed
        Task.start(fn ->
          Process.sleep(100)

          if Process.alive?(pid) do
            Process.exit(pid, :kill)
          end
        end)

        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
