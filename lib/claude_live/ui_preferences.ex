defmodule ClaudeLive.UIPreferences do
  @moduledoc """
  Manages global UI preferences that persist across LiveView navigation.
  This includes sidebar collapse state and other UI settings.
  """
  use GenServer
  require Logger

  @topic "ui_preferences"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_preferences do
    GenServer.call(__MODULE__, :get_preferences)
  end

  def set_sidebar_collapsed(collapsed) when is_boolean(collapsed) do
    GenServer.call(__MODULE__, {:set_sidebar_collapsed, collapsed})
  end

  def toggle_sidebar do
    GenServer.call(__MODULE__, :toggle_sidebar)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(ClaudeLive.PubSub, @topic)
  end

  # Server Callbacks

  @impl true
  def init(_args) do
    initial_state = %{
      sidebar_collapsed: false,
      # Can add more UI preferences here in the future
      theme: "dark",
      terminal_font_size: 14
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_preferences, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:set_sidebar_collapsed, collapsed}, _from, state) do
    new_state = Map.put(state, :sidebar_collapsed, collapsed)
    broadcast_update(:sidebar_collapsed, collapsed)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:toggle_sidebar, _from, state) do
    new_collapsed = !state.sidebar_collapsed
    new_state = Map.put(state, :sidebar_collapsed, new_collapsed)
    broadcast_update(:sidebar_collapsed, new_collapsed)
    {:reply, new_collapsed, new_state}
  end

  # Private functions

  defp broadcast_update(key, value) do
    Phoenix.PubSub.broadcast(
      ClaudeLive.PubSub,
      @topic,
      {:ui_preference_updated, {key, value}}
    )
  end
end
