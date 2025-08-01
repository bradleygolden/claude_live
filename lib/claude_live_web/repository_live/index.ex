defmodule ClaudeLiveWeb.RepositoryLive.Index do
  use ClaudeLiveWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Repositories
        <:actions>
          <.button variant="primary" navigate={~p"/repos/new"}>
            <.icon name="hero-plus" /> New Repository
          </.button>
        </:actions>
      </.header>

      <.table
        id="repositories"
        rows={@streams.repositories}
        row_click={fn {_id, repository} -> JS.navigate(~p"/repos/#{repository}") end}
      >
        <:col :let={{_id, repository}} label="Id">{repository.id}</:col>

        <:col :let={{_id, repository}} label="Name">{repository.name}</:col>

        <:col :let={{_id, repository}} label="Path">{repository.path}</:col>

        <:action :let={{_id, repository}}>
          <div class="sr-only">
            <.link navigate={~p"/repos/#{repository}"}>Show</.link>
          </div>

          <.link navigate={~p"/repos/#{repository}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, repository}}>
          <.link
            phx-click={JS.push("delete", value: %{id: repository.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Repositories")
     |> stream(:repositories, Ash.read!(ClaudeLive.Claude.Repository))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    repository = Ash.get!(ClaudeLive.Claude.Repository, id)
    Ash.destroy!(repository)

    {:noreply, stream_delete(socket, :repositories, repository)}
  end
end
