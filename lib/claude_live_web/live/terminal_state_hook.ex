defmodule ClaudeLiveWeb.TerminalStateHook do
  @moduledoc """
  LiveView on_mount hook that manages global terminal state and UI preferences across all LiveViews.
  This hook subscribes to terminal and UI preference PubSub updates and initializes state.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  require Logger

  def on_mount(:default, _params, _session, socket) do
    socket =
      if connected?(socket) do
        # Subscribe to terminal updates
        ClaudeLive.TerminalManager.subscribe()
        terminals = ClaudeLive.TerminalManager.list_terminals()

        # Subscribe to UI preferences
        ClaudeLive.UIPreferences.subscribe()
        ui_preferences = ClaudeLive.UIPreferences.get_preferences()

        socket
        |> assign(:global_terminals, terminals)
        |> assign(:ui_preferences, ui_preferences)
        |> attach_hook(:terminal_state, :handle_info, &handle_terminal_info/2)
      else
        socket
        |> assign(:global_terminals, %{})
        |> assign(:ui_preferences, %{sidebar_collapsed: false})
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

  defp handle_terminal_info({:ui_preference_updated, {key, value}}, socket) do
    updated_preferences = Map.put(socket.assigns.ui_preferences, key, value)
    {:cont, assign(socket, :ui_preferences, updated_preferences)}
  end

  defp handle_terminal_info(_msg, socket) do
    {:cont, socket}
  end
end
