defmodule ClaudeLiveWeb.TerminalStateHook do
  @moduledoc """
  LiveView on_mount hook that manages global terminal state across all LiveViews.
  This hook subscribes to terminal PubSub updates and initializes terminal state.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  require Logger

  def on_mount(:default, _params, _session, socket) do
    socket =
      if connected?(socket) do
        ClaudeLive.TerminalManager.subscribe()
        terminals = ClaudeLive.TerminalManager.list_terminals()

        socket
        |> assign(:global_terminals, terminals)
        |> attach_hook(:terminal_state, :handle_info, &handle_terminal_info/2)
      else
        assign(socket, :global_terminals, %{})
      end

    {:cont, socket}
  end

  defp handle_terminal_info({:terminal_updated, {terminal_id, terminal_data}}, socket) do
    updated_terminals = Map.put(socket.assigns.global_terminals, terminal_id, terminal_data)
    {:cont, assign(socket, :global_terminals, updated_terminals)}
  end

  defp handle_terminal_info({:terminal_deleted, terminal_id}, socket) do
    updated_terminals = Map.delete(socket.assigns.global_terminals, terminal_id)
    {:cont, assign(socket, :global_terminals, updated_terminals)}
  end

  defp handle_terminal_info({:terminal_status_updated, {terminal_id, connected}}, socket) do
    case Map.get(socket.assigns.global_terminals, terminal_id) do
      nil ->
        {:cont, socket}

      terminal ->
        updated_terminal = Map.put(terminal, :connected, connected)

        updated_terminals =
          Map.put(socket.assigns.global_terminals, terminal_id, updated_terminal)

        {:cont, assign(socket, :global_terminals, updated_terminals)}
    end
  end

  defp handle_terminal_info({:terminal_activated, {_terminal_id, _session_id}}, socket) do
    {:cont, socket}
  end

  defp handle_terminal_info(_msg, socket) do
    {:cont, socket}
  end
end
