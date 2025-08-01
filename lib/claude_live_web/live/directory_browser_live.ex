defmodule ClaudeLiveWeb.DirectoryBrowserLive do
  use ClaudeLiveWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Start at the user's home directory
    home_dir = System.user_home!()

    {:ok,
     socket
     |> assign(:current_path, home_dir)
     |> assign(:selected_path, nil)
     |> load_directory_contents()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 class="text-2xl font-bold mb-4 text-gray-900 dark:text-gray-100">
          Select Repository Directory
        </h2>
        
    <!-- Current Path -->
        <div class="mb-4 p-3 bg-gray-100 dark:bg-gray-700 rounded">
          <p class="text-sm font-mono text-gray-700 dark:text-gray-300">
            Current: {@current_path}
          </p>
        </div>
        
    <!-- Directory Contents -->
        <div class="border dark:border-gray-700 rounded-lg overflow-hidden mb-4">
          <div class="max-h-96 overflow-y-auto">
            <!-- Parent Directory -->
            <%= if @current_path != "/" do %>
              <div
                class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer border-b dark:border-gray-700"
                phx-click="navigate"
                phx-value-path={Path.dirname(@current_path)}
              >
                <div class="flex items-center">
                  <.icon name="hero-arrow-up" class="w-5 h-5 mr-2 text-gray-500" />
                  <span class="text-gray-600 dark:text-gray-400">..</span>
                </div>
              </div>
            <% end %>
            
    <!-- Directories -->
            <%= for {name, type, path} <- @entries, type == :directory do %>
              <div
                class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer border-b dark:border-gray-700"
                phx-click="navigate"
                phx-value-path={path}
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <.icon name="hero-folder" class="w-5 h-5 mr-2 text-blue-500" />
                    <span class="text-gray-900 dark:text-gray-100">{name}</span>
                  </div>
                  <%= if is_git_repo?(path) do %>
                    <span class="text-xs bg-green-100 dark:bg-green-800 text-green-800 dark:text-green-100 px-2 py-1 rounded">
                      Git Repo
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            
    <!-- Files (shown but not selectable) -->
            <%= for {name, type, _path} <- @entries, type == :file do %>
              <div class="p-3 opacity-50 border-b dark:border-gray-700">
                <div class="flex items-center">
                  <.icon name="hero-document" class="w-5 h-5 mr-2 text-gray-400" />
                  <span class="text-gray-600 dark:text-gray-400">{name}</span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Actions -->
        <div class="flex gap-4">
          <.button
            type="button"
            phx-click="select-current"
            variant="primary"
            disabled={!is_git_repo?(@current_path)}
          >
            Select This Directory
          </.button>
          <.button type="button" phx-click="cancel">
            Cancel
          </.button>
        </div>

        <%= if !is_git_repo?(@current_path) do %>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Only Git repositories can be selected. Navigate to a directory containing a .git folder.
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("navigate", %{"path" => path}, socket) do
    {:noreply,
     socket
     |> assign(:current_path, path)
     |> load_directory_contents()}
  end

  def handle_event("select-current", _params, socket) do
    path = socket.assigns.current_path

    if is_git_repo?(path) do
      # Extract repository name from path
      name = Path.basename(path)

      # Create the repository
      params = %{"name" => name, "path" => path}

      case Ash.create(ClaudeLive.Claude.Repository, params) do
        {:ok, repository} ->
          {:noreply,
           socket
           |> put_flash(:info, "Repository created successfully")
           |> push_navigate(to: ~p"/dashboard/#{repository.id}")}

        {:error, _error} ->
          {:noreply, put_flash(socket, :error, "Failed to create repository")}
      end
    else
      {:noreply, put_flash(socket, :error, "Selected directory is not a Git repository")}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  defp load_directory_contents(socket) do
    path = socket.assigns.current_path

    entries =
      case File.ls(path) do
        {:ok, files} ->
          files
          # Hide hidden files
          |> Enum.reject(&String.starts_with?(&1, "."))
          |> Enum.map(fn name ->
            full_path = Path.join(path, name)
            type = if File.dir?(full_path), do: :directory, else: :file
            {name, type, full_path}
          end)
          |> Enum.sort_by(fn {name, type, _} -> {type != :directory, name} end)

        {:error, _} ->
          []
      end

    assign(socket, :entries, entries)
  end

  defp is_git_repo?(path) do
    git_path = Path.join(path, ".git")
    File.dir?(git_path)
  end
end
