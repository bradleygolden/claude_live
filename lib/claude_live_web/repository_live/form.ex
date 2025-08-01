defmodule ClaudeLiveWeb.RepositoryLive.Form do
  use ClaudeLiveWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage repository records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="repository-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" /><.input
          field={@form[:path]}
          type="text"
          label="Path"
        />

        <.button phx-disable-with="Saving..." variant="primary">Save Repository</.button>
        <.button navigate={return_path(@return_to, @repository)}>Cancel</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    repository =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(ClaudeLive.Claude.Repository, id)
      end

    action = if is_nil(repository), do: "New", else: "Edit"
    page_title = action <> " " <> "Repository"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(repository: repository)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"repository" => repository_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, repository_params))}
  end

  def handle_event("save", %{"repository" => repository_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: repository_params) do
      {:ok, repository} ->
        notify_parent({:saved, repository})

        socket =
          socket
          |> put_flash(:info, "Repository #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, repository))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{repository: repository}} = socket) do
    form =
      if repository do
        AshPhoenix.Form.for_update(repository, :update, as: "repository")
      else
        AshPhoenix.Form.for_create(ClaudeLive.Claude.Repository, :create, as: "repository")
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _repository), do: ~p"/repos"
  defp return_path("show", repository), do: ~p"/repos/#{repository.id}"
end
