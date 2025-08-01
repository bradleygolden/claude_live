defmodule ClaudeLiveWeb.RepositoryLive.Show do
  use ClaudeLiveWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Repository {@repository.id}
        <:subtitle>This is a repository record from your database.</:subtitle>

        <:actions>
          <.button navigate={~p"/repos"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/repos/#{@repository}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Repository
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@repository.id}</:item>

        <:item title="Name">{@repository.name}</:item>

        <:item title="Path">{@repository.path}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Repository")
     |> assign(:repository, Ash.get!(ClaudeLive.Claude.Repository, id))}
  end
end
