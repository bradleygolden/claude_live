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
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black">
      <!-- Header -->
      <div class="bg-gray-900/80 backdrop-blur-sm border-b border-gray-800/50">
        <div class="max-w-7xl mx-auto px-6 py-4">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                Add Repository
              </h1>
              <p class="text-sm text-gray-400 mt-1">
                Navigate to a Git repository to add it to your workspace
              </p>
            </div>
            <.link
              navigate={~p"/"}
              class="px-4 py-2 text-sm font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 rounded-lg transition-all duration-200 cursor-pointer flex items-center gap-2"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Dashboard
            </.link>
          </div>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-6 py-8">
        <div class="bg-gray-900/50 backdrop-blur-sm rounded-2xl border border-gray-800/50 overflow-hidden">
          <!-- Current Path -->
          <div class="p-6 border-b border-gray-800/50">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
                  <.icon name="hero-folder-open" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <p class="text-xs text-gray-500 uppercase tracking-wider">Current Directory</p>
                  <p class="text-sm font-mono text-gray-300">
                    {@current_path}
                  </p>
                </div>
              </div>
              <%= if is_git_repo?(@current_path) do %>
                <span class="inline-flex items-center gap-2 text-sm bg-emerald-950/50 text-emerald-400 px-4 py-2 rounded-full border border-emerald-900/50">
                  <.icon name="hero-check-circle" class="w-4 h-4" /> Git Repository
                </span>
              <% end %>
            </div>
          </div>
          
    <!-- Directory Browser -->
          <div class="flex">
            <!-- Directory List -->
            <div class="flex-1 border-r border-gray-800/50">
              <div class="max-h-[500px] overflow-y-auto">
                <!-- Parent Directory -->
                <%= if @current_path != "/" do %>
                  <div
                    class="px-6 py-4 hover:bg-gray-800/30 cursor-pointer border-b border-gray-800/50 transition-all duration-200 group"
                    phx-click="navigate"
                    phx-value-path={Path.dirname(@current_path)}
                  >
                    <div class="flex items-center">
                      <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mr-3 group-hover:from-gray-600 group-hover:to-gray-700 transition-all duration-200">
                        <.icon name="hero-arrow-up" class="w-5 h-5 text-gray-400" />
                      </div>
                      <span class="text-gray-400 font-medium">Parent Directory</span>
                    </div>
                  </div>
                <% end %>
                
    <!-- Directories -->
                <%= for {name, type, path} <- @entries, type == :directory do %>
                  <div
                    class="px-6 py-4 hover:bg-gray-800/30 cursor-pointer border-b border-gray-800/50 transition-all duration-200 group"
                    phx-click="navigate"
                    phx-value-path={path}
                  >
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div class={[
                          "w-10 h-10 rounded-lg flex items-center justify-center mr-3 transition-all duration-200",
                          (is_git_repo?(path) &&
                             "bg-gradient-to-br from-emerald-500 to-green-600 group-hover:from-emerald-400 group-hover:to-green-500") ||
                            "bg-gradient-to-br from-blue-600 to-indigo-700 group-hover:from-blue-500 group-hover:to-indigo-600"
                        ]}>
                          <.icon name="hero-folder" class="w-5 h-5 text-white" />
                        </div>
                        <div>
                          <p class="text-gray-100 font-medium">{name}</p>
                          <%= if is_git_repo?(path) do %>
                            <p class="text-xs text-emerald-400 mt-0.5">Contains .git</p>
                          <% end %>
                        </div>
                      </div>
                      <.icon
                        name="hero-chevron-right"
                        class="w-5 h-5 text-gray-600 group-hover:text-gray-400"
                      />
                    </div>
                  </div>
                <% end %>
                
    <!-- Files (shown but not selectable) -->
                <%= for {name, type, _path} <- @entries, type == :file do %>
                  <div class="px-6 py-4 opacity-40 border-b border-gray-800/50">
                    <div class="flex items-center">
                      <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mr-3">
                        <.icon name="hero-document" class="w-5 h-5 text-gray-500" />
                      </div>
                      <span class="text-gray-500">{name}</span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
            
    <!-- Info Panel -->
            <div class="w-80 p-6 bg-gray-950/50">
              <h3 class="text-sm font-bold text-gray-300 uppercase tracking-wider mb-4">
                Repository Info
              </h3>

              <%= if is_git_repo?(@current_path) do %>
                <div class="space-y-4">
                  <div class="p-4 bg-emerald-950/30 rounded-lg border border-emerald-900/50">
                    <div class="flex items-center gap-3 mb-3">
                      <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
                        <.icon name="hero-check" class="w-4 h-4 text-white" />
                      </div>
                      <p class="text-sm font-medium text-emerald-400">Valid Repository</p>
                    </div>
                    <p class="text-xs text-gray-400">
                      This directory contains a Git repository and can be added to your workspace.
                    </p>
                  </div>

                  <button
                    type="button"
                    phx-click="select-current"
                    class="w-full px-6 py-3 text-sm font-medium bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-400 hover:to-purple-500 text-white rounded-xl shadow-lg shadow-blue-500/25 transition-all duration-200 cursor-pointer flex items-center justify-center gap-2"
                  >
                    <.icon name="hero-plus-circle" class="w-5 h-5" /> Add This Repository
                  </button>
                </div>
              <% else %>
                <div class="p-4 bg-gray-800/30 rounded-lg border border-gray-700/50">
                  <div class="flex items-center gap-3 mb-3">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-600 to-orange-700 flex items-center justify-center">
                      <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-white" />
                    </div>
                    <p class="text-sm font-medium text-amber-400">Not a Repository</p>
                  </div>
                  <p class="text-xs text-gray-400">
                    Navigate to a directory containing a .git folder to add it to your workspace.
                  </p>
                </div>
              <% end %>

              <div class="mt-6 pt-6 border-t border-gray-800/50">
                <h4 class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-3">
                  Quick Navigation
                </h4>
                <div class="space-y-2">
                  <button
                    phx-click="navigate"
                    phx-value-path={System.user_home!()}
                    class="w-full text-left px-3 py-2 text-sm text-gray-400 hover:text-gray-200 hover:bg-gray-800/30 rounded-lg transition-all duration-200 cursor-pointer flex items-center gap-2"
                  >
                    <.icon name="hero-home" class="w-4 h-4" /> Home Directory
                  </button>
                  <%= if File.exists?(Path.join(System.user_home!(), "Development")) do %>
                    <button
                      phx-click="navigate"
                      phx-value-path={Path.join(System.user_home!(), "Development")}
                      class="w-full text-left px-3 py-2 text-sm text-gray-400 hover:text-gray-200 hover:bg-gray-800/30 rounded-lg transition-all duration-200 cursor-pointer flex items-center gap-2"
                    >
                      <.icon name="hero-code-bracket" class="w-4 h-4" /> Development
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
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
