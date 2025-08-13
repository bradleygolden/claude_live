defmodule ClaudeLiveWeb.RemoteCloneLive do
  use ClaudeLiveWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    auth_status = check_gh_auth()

    {:ok,
     socket
     |> assign(:auth_status, auth_status)
     |> assign(:repo_input, "")
     |> assign(:repo_info, nil)
     |> assign(:clone_status, :idle)
     |> assign(:clone_progress, "")
     |> assign(:error_message, nil)
     |> assign(:show_fork_dialog, false)
     |> assign(:clone_path, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black">
      <div class="bg-gray-900/80 backdrop-blur-sm border-b border-gray-800/50">
        <div class="max-w-4xl mx-auto px-6 py-4">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                Clone from GitHub
              </h1>
              <p class="text-sm text-gray-400 mt-1">
                Clone any GitHub repository to your workspace
              </p>
            </div>
            <.link
              navigate={~p"/"}
              class="px-4 py-2 text-sm font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 rounded-lg transition-all duration-200 cursor-pointer flex items-center gap-2"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Terminal
            </.link>
          </div>
        </div>
      </div>

      <div class="max-w-4xl mx-auto px-6 py-8">
        <%= if @auth_status == :authenticated do %>
          <div class="bg-gray-900/50 backdrop-blur-sm rounded-2xl border border-gray-800/50 overflow-hidden">
            <div class="p-8">
              <form phx-submit="fetch-repo" phx-change="validate-input">
                <div class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-300 mb-2">
                      GitHub Repository
                    </label>
                    <div class="flex gap-3">
                      <input
                        type="text"
                        name="repo_url"
                        value={@repo_input}
                        placeholder="owner/repo or GitHub URL"
                        class="flex-1 px-4 py-3 bg-gray-800/50 border border-gray-700 rounded-lg text-gray-100 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        disabled={@clone_status == :cloning}
                        autocomplete="off"
                      />
                      <button
                        type="submit"
                        disabled={@repo_input == "" || @clone_status == :cloning}
                        class={[
                          "px-6 py-3 font-medium rounded-lg transition-all duration-200",
                          if @repo_input == "" || @clone_status == :cloning do
                            "bg-gray-700 text-gray-400 cursor-not-allowed"
                          else
                            "bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-400 hover:to-purple-500 text-white shadow-lg shadow-blue-500/25 cursor-pointer"
                          end
                        ]}
                      >
                        {if @clone_status == :cloning, do: "Cloning...", else: "Fetch Info"}
                      </button>
                    </div>
                    <div class="mt-2 text-xs text-gray-500">
                      Examples: elixir-lang/elixir, phoenixframework/phoenix, https://github.com/dashbitco/broadway
                    </div>
                  </div>
                </div>
              </form>

              <%= if @error_message do %>
                <div class="mt-4 p-4 bg-red-950/30 border border-red-900/50 rounded-lg">
                  <div class="flex items-center gap-3">
                    <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-400" />
                    <p class="text-sm text-red-400">{@error_message}</p>
                  </div>
                </div>
              <% end %>

              <%= if @repo_info do %>
                <div class="mt-6 p-6 bg-gray-800/30 rounded-xl border border-gray-700/50">
                  <div class="flex items-start gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center flex-shrink-0">
                      <.icon name="hero-code-bracket" class="w-6 h-6 text-white" />
                    </div>
                    <div class="flex-1">
                      <div class="flex items-center gap-3">
                        <h3 class="text-lg font-semibold text-gray-100">
                          {@repo_info["nameWithOwner"]}
                        </h3>
                        <a
                          href={@repo_info["url"]}
                          target="_blank"
                          rel="noopener noreferrer"
                          class="inline-flex items-center gap-1 text-xs text-blue-400 hover:text-blue-300 transition-colors"
                          title="View on GitHub"
                        >
                          <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
                          View on GitHub
                        </a>
                      </div>
                      <%= if @repo_info["description"] do %>
                        <p class="text-sm text-gray-400 mt-1">{@repo_info["description"]}</p>
                      <% end %>
                      <div class="flex items-center gap-4 mt-3 text-xs text-gray-500">
                        <span class="flex items-center gap-1">
                          <.icon name="hero-star" class="w-4 h-4" />
                          {@repo_info["stargazerCount"]} stars
                        </span>
                        <%= if @repo_info["isFork"] do %>
                          <span class="flex items-center gap-1 text-amber-400">
                            <.icon name="hero-arrow-path" class="w-4 h-4" /> Fork of
                            <a
                              href={@repo_info["parent"]["url"]}
                              target="_blank"
                              rel="noopener noreferrer"
                              class="underline hover:no-underline"
                            >
                              {@repo_info["parent"]["nameWithOwner"]}
                            </a>
                          </span>
                        <% end %>
                        <span class={[
                          "px-2 py-0.5 rounded-full",
                          if(@repo_info["isPrivate"],
                            do: "bg-amber-950/50 text-amber-400",
                            else: "bg-emerald-950/50 text-emerald-400"
                          )
                        ]}>
                          {if @repo_info["isPrivate"], do: "Private", else: "Public"}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="mt-6 flex gap-3">
                    <%= if @repo_info["isFork"] && @repo_info["parent"] do %>
                      <button
                        phx-click="clone-fork"
                        disabled={@clone_status == :cloning}
                        class="flex-1 px-4 py-2.5 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-400 hover:to-purple-500 text-white font-medium rounded-lg transition-all duration-200 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Clone Your Fork
                      </button>
                      <button
                        phx-click="clone-upstream"
                        disabled={@clone_status == :cloning}
                        class="flex-1 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-gray-100 font-medium rounded-lg transition-all duration-200 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Clone Original ({@repo_info["parent"]["owner"]["login"]}/{@repo_info["parent"][
                          "name"
                        ]})
                      </button>
                    <% else %>
                      <%= if @repo_info["viewerPermission"] in ["ADMIN", "MAINTAIN", "WRITE"] do %>
                        <button
                          phx-click="clone-direct"
                          disabled={@clone_status == :cloning}
                          class="flex-1 px-4 py-2.5 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-400 hover:to-purple-500 text-white font-medium rounded-lg transition-all duration-200 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          Clone Repository
                        </button>
                      <% else %>
                        <button
                          phx-click="show-fork-dialog"
                          disabled={@clone_status == :cloning}
                          class="flex-1 px-4 py-2.5 bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-400 hover:to-green-500 text-white font-medium rounded-lg transition-all duration-200 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          Fork & Clone
                        </button>
                        <button
                          phx-click="clone-direct"
                          disabled={@clone_status == :cloning}
                          class="flex-1 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-gray-100 font-medium rounded-lg transition-all duration-200 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          Clone Only (Read-only)
                        </button>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%= if @clone_status == :cloning do %>
                <div class="mt-6 p-4 bg-blue-950/30 border border-blue-900/50 rounded-lg">
                  <div class="flex items-center gap-3">
                    <div class="animate-spin">
                      <.icon name="hero-arrow-path" class="w-5 h-5 text-blue-400" />
                    </div>
                    <div class="flex-1">
                      <p class="text-sm font-medium text-blue-400">Cloning repository...</p>
                      <%= if @clone_progress != "" do %>
                        <p class="text-xs text-gray-400 mt-1 font-mono">{@clone_progress}</p>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <%= if @show_fork_dialog do %>
            <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
              <div class="bg-gray-900 rounded-2xl p-6 max-w-md w-full mx-4 border border-gray-800">
                <h3 class="text-xl font-bold text-gray-100 mb-4">Fork & Clone Repository</h3>
                <p class="text-sm text-gray-400 mb-6">
                  This will create a fork under your GitHub account and clone it locally. This is recommended for contributing back to the project.
                </p>
                <div class="flex gap-3">
                  <button
                    phx-click="confirm-fork"
                    class="flex-1 px-4 py-2.5 bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-400 hover:to-green-500 text-white font-medium rounded-lg transition-all duration-200 cursor-pointer"
                  >
                    Fork & Clone
                  </button>
                  <button
                    phx-click="cancel-fork"
                    class="flex-1 px-4 py-2.5 bg-gray-700 hover:bg-gray-600 text-gray-100 font-medium rounded-lg transition-all duration-200 cursor-pointer"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        <% else %>
          <div class="bg-gray-900/50 backdrop-blur-sm rounded-2xl border border-gray-800/50 p-8">
            <div class="text-center">
              <div class="w-16 h-16 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-exclamation-triangle" class="w-8 h-8 text-white" />
              </div>
              <%= if @auth_status == :not_installed do %>
                <h2 class="text-xl font-bold text-gray-100 mb-2">GitHub CLI Not Installed</h2>
                <p class="text-gray-400 mb-6">
                  Please install the GitHub CLI to use this feature.
                </p>
                <div class="bg-gray-800/50 rounded-lg p-4 text-left max-w-md mx-auto">
                  <p class="text-sm font-medium text-gray-300 mb-2">
                    Install via Homebrew (macOS):
                  </p>
                  <code class="block bg-gray-900 p-3 rounded text-green-400 font-mono text-sm mb-3">
                    brew install gh
                  </code>
                  <p class="text-xs text-gray-400">
                    For other platforms, visit:
                    <a
                      href="https://cli.github.com"
                      target="_blank"
                      class="text-blue-400 hover:text-blue-300"
                    >
                      cli.github.com
                    </a>
                  </p>
                </div>
              <% else %>
                <h2 class="text-xl font-bold text-gray-100 mb-2">GitHub Authentication Required</h2>
                <p class="text-gray-400 mb-6">
                  Please authenticate with GitHub CLI to clone repositories.
                </p>
                <div class="bg-gray-800/50 rounded-lg p-4 text-left max-w-md mx-auto">
                  <p class="text-sm font-medium text-gray-300 mb-2">
                    Run this command in your terminal:
                  </p>
                  <code class="block bg-gray-900 p-3 rounded text-green-400 font-mono text-sm">
                    gh auth login
                  </code>
                </div>
              <% end %>
              <button
                phx-click="check-auth"
                class="mt-6 px-6 py-2.5 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-400 hover:to-purple-500 text-white font-medium rounded-lg transition-all duration-200 cursor-pointer"
              >
                Check Status Again
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate-input", %{"repo_url" => url}, socket) do
    {:noreply, assign(socket, :repo_input, url)}
  end

  def handle_event("fetch-repo", %{"repo_url" => url}, socket) do
    socket = assign(socket, error_message: nil, repo_info: nil)

    case parse_repo_input(url) do
      {:ok, owner, repo} ->
        case fetch_repo_info(owner, repo) do
          {:ok, repo_info} ->
            {:noreply, assign(socket, :repo_info, repo_info)}

          {:error, message} ->
            {:noreply, assign(socket, :error_message, message)}
        end

      {:error, message} ->
        {:noreply, assign(socket, :error_message, message)}
    end
  end

  def handle_event("clone-direct", _params, socket) do
    clone_repository(socket, :direct)
  end

  def handle_event("clone-fork", _params, socket) do
    clone_repository(socket, :fork)
  end

  def handle_event("clone-upstream", _params, socket) do
    repo_info = socket.assigns.repo_info
    parent = repo_info["parent"]

    socket = assign(socket, :repo_info, parent)
    clone_repository(socket, :direct)
  end

  def handle_event("show-fork-dialog", _params, socket) do
    {:noreply, assign(socket, :show_fork_dialog, true)}
  end

  def handle_event("confirm-fork", _params, socket) do
    socket = assign(socket, :show_fork_dialog, false)
    clone_repository(socket, :fork_and_clone)
  end

  def handle_event("cancel-fork", _params, socket) do
    {:noreply, assign(socket, :show_fork_dialog, false)}
  end

  def handle_event("check-auth", _params, socket) do
    {:noreply, assign(socket, :auth_status, check_gh_auth())}
  end

  @impl true
  def handle_info({:clone_output, output}, socket) do
    {:noreply, assign(socket, :clone_progress, output)}
  end

  def handle_info({:clone_complete, {:ok, clone_path}}, socket) do
    repo_info = socket.assigns.repo_info
    repo_name = repo_info["name"]
    owner = repo_info["owner"]["login"]

    params = %{
      "name" => repo_name,
      "path" => clone_path,
      "source_type" => determine_source_type(socket.assigns),
      "remote_url" => repo_info["url"],
      "github_owner" => owner,
      "github_name" => repo_name
    }

    params =
      if repo_info["isFork"] && repo_info["parent"] do
        Map.put(params, "upstream_url", repo_info["parent"]["url"])
      else
        params
      end

    case Ash.create(ClaudeLive.Claude.Repository, params) do
      {:ok, _repository} ->
        {:noreply,
         socket
         |> put_flash(:info, "Repository cloned successfully!")
         |> push_navigate(to: ~p"/")}

      {:error, _error} ->
        {:noreply,
         socket
         |> assign(:clone_status, :idle)
         |> assign(:error_message, "Failed to create repository record")}
    end
  end

  def handle_info({:clone_complete, {:error, message}}, socket) do
    {:noreply,
     socket
     |> assign(:clone_status, :idle)
     |> assign(:clone_progress, "")
     |> assign(:error_message, message)}
  end

  defp check_gh_auth do
    case System.find_executable("gh") do
      nil ->
        :not_installed

      _path ->
        case System.cmd("gh", ["auth", "status"], stderr_to_stdout: true) do
          {output, 0} ->
            if String.contains?(output, "Logged in") do
              :authenticated
            else
              :not_authenticated
            end

          _ ->
            :not_authenticated
        end
    end
  end

  defp parse_repo_input(input) do
    input = String.trim(input)

    cond do
      String.match?(input, ~r/^[\w\-\.]+\/[\w\-\.]+$/) ->
        [owner, repo] = String.split(input, "/")
        {:ok, owner, repo}

      String.contains?(input, "github.com") ->
        case extract_owner_repo_from_url(input) do
          {owner, repo} when owner != "" and repo != "" ->
            {:ok, owner, repo}

          _ ->
            {:error, "Invalid GitHub URL format"}
        end

      true ->
        {:error, "Invalid input format. Use 'owner/repo' or a GitHub URL"}
    end
  end

  defp extract_owner_repo_from_url(url) do
    url = String.trim(url)

    cond do
      String.starts_with?(url, "https://github.com/") ->
        url
        |> String.replace("https://github.com/", "")
        |> String.replace(".git", "")
        |> String.split("/")
        |> case do
          [owner, repo | _] -> {owner, repo}
          _ -> {"", ""}
        end

      String.starts_with?(url, "git@github.com:") ->
        url
        |> String.replace("git@github.com:", "")
        |> String.replace(".git", "")
        |> String.split("/")
        |> case do
          [owner, repo | _] -> {owner, repo}
          _ -> {"", ""}
        end

      true ->
        {"", ""}
    end
  end

  defp fetch_repo_info(owner, repo) do
    json_fields =
      "name,nameWithOwner,description,url,isPrivate,isFork,parent,stargazerCount,defaultBranchRef,owner,viewerPermission"

    case System.cmd("gh", ["repo", "view", "#{owner}/#{repo}", "--json", json_fields],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, data} -> {:ok, data}
          {:error, _} -> {:error, "Failed to parse repository information"}
        end

      {output, _} ->
        cond do
          String.contains?(output, "Could not resolve to a Repository") ->
            {:error, "Repository not found"}

          String.contains?(output, "HTTP 404") ->
            {:error, "Repository not found or you don't have access"}

          true ->
            {:error, "Failed to fetch repository information"}
        end
    end
  end

  defp clone_repository(socket, mode) do
    repo_info = socket.assigns.repo_info
    owner = repo_info["owner"]["login"]
    repo_name = repo_info["name"]

    base_path = Path.join([System.user_home!(), "claude_live_repos"])
    File.mkdir_p!(base_path)

    clone_path = Path.join([base_path, owner, repo_name])

    if File.exists?(clone_path) do
      {:noreply, assign(socket, :error_message, "Repository already exists at #{clone_path}")}
    else
      socket =
        socket
        |> assign(:clone_status, :cloning)
        |> assign(:clone_progress, "Initializing...")
        |> assign(:clone_path, clone_path)

      self_pid = self()

      Task.start(fn ->
        result =
          case mode do
            :direct ->
              run_clone_direct(owner, repo_name, clone_path, self_pid)

            :fork ->
              run_clone_fork_with_upstream(owner, repo_name, clone_path, self_pid, repo_info)

            :fork_and_clone ->
              run_fork_and_clone(owner, repo_name, clone_path, self_pid)
          end

        send(self_pid, {:clone_complete, result})
      end)

      {:noreply, socket}
    end
  end

  defp run_clone_direct(owner, repo, clone_path, pid) do
    send(pid, {:clone_output, "Cloning repository..."})

    case System.cmd("gh", ["repo", "clone", "#{owner}/#{repo}", clone_path],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        {:ok, clone_path}

      {output, _} ->
        {:error, "Clone failed: #{output}"}
    end
  end

  defp run_clone_fork_with_upstream(owner, repo, clone_path, pid, repo_info) do
    send(pid, {:clone_output, "Cloning fork..."})

    case System.cmd("gh", ["repo", "clone", "#{owner}/#{repo}", clone_path],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        if repo_info["parent"] do
          parent_owner = repo_info["parent"]["owner"]["login"]
          parent_name = repo_info["parent"]["name"]

          send(pid, {:clone_output, "Setting up upstream remote..."})

          case System.cmd(
                 "git",
                 [
                   "remote",
                   "add",
                   "upstream",
                   "https://github.com/#{parent_owner}/#{parent_name}.git"
                 ],
                 cd: clone_path,
                 stderr_to_stdout: true
               ) do
            {_output, 0} ->
              send(pid, {:clone_output, "Upstream remote configured"})
              {:ok, clone_path}

            {output, _} ->
              if String.contains?(output, "already exists") do
                {:ok, clone_path}
              else
                Logger.warning("Failed to add upstream remote: #{output}")
                {:ok, clone_path}
              end
          end
        else
          {:ok, clone_path}
        end

      {output, _} ->
        {:error, "Clone failed: #{output}"}
    end
  end

  defp run_fork_and_clone(owner, repo, clone_path, pid) do
    send(pid, {:clone_output, "Creating fork..."})

    case System.cmd("gh", ["repo", "fork", "#{owner}/#{repo}", "--clone=false"],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        send(pid, {:clone_output, "Fork created. Cloning..."})

        case System.cmd("gh", ["api", "user", "--jq", ".login"], stderr_to_stdout: true) do
          {username, 0} ->
            username = String.trim(username)

            case System.cmd(
                   "gh",
                   ["repo", "clone", "#{username}/#{repo}", clone_path],
                   stderr_to_stdout: true
                 ) do
              {_output, 0} ->
                case System.cmd(
                       "git",
                       ["remote", "add", "upstream", "https://github.com/#{owner}/#{repo}.git"],
                       cd: clone_path,
                       stderr_to_stdout: true
                     ) do
                  {_output, 0} ->
                    send(pid, {:clone_output, "Upstream remote configured"})
                    {:ok, clone_path}

                  {output, _} ->
                    if String.contains?(output, "already exists") do
                      {:ok, clone_path}
                    else
                      Logger.warning("Failed to add upstream remote: #{output}")
                      {:ok, clone_path}
                    end
                end

              {output, _} ->
                {:error, "Clone failed: #{output}"}
            end

          _ ->
            {:error, "Failed to get current user"}
        end

      {output, _} ->
        if String.contains?(output, "already exists") do
          send(pid, {:clone_output, "Fork already exists. Cloning..."})

          case System.cmd("gh", ["api", "user", "--jq", ".login"], stderr_to_stdout: true) do
            {username, 0} ->
              username = String.trim(username)
              run_clone_direct(username, repo, clone_path, pid)

            _ ->
              {:error, "Failed to get current user"}
          end
        else
          {:error, "Fork failed: #{output}"}
        end
    end
  end

  defp determine_source_type(assigns) do
    cond do
      assigns.repo_info["isFork"] -> :forked
      true -> :cloned
    end
  end
end
