defmodule ClaudeLiveWeb.TerminalLive do
  @moduledoc """
  LiveView for a single terminal instance.
  Each terminal runs at /terminal/:terminal_id providing complete isolation.
  """
  use ClaudeLiveWeb, :live_view
  require Logger

  @us_cities [
    "Aberdeen",
    "Abilene",
    "Akron",
    "Albany",
    "Alexandria",
    "Allentown",
    "Amarillo",
    "Anaheim",
    "Anchorage",
    "Arlington",
    "Asheville",
    "Athens",
    "Atlanta",
    "Auburn",
    "Augusta",
    "Austin",
    "Bakersfield",
    "Baltimore",
    "Bangor",
    "Baton-Rouge",
    "Beaumont",
    "Bellevue",
    "Berkeley",
    "Bethlehem",
    "Birmingham",
    "Bloomington",
    "Boise",
    "Boston",
    "Boulder",
    "Bridgeport",
    "Brooklyn",
    "Buffalo",
    "Burlington",
    "Cambridge",
    "Camden",
    "Canton",
    "Carlsbad",
    "Carrollton",
    "Cary",
    "Cedar-Rapids",
    "Centennial",
    "Chandler",
    "Charleston",
    "Charlotte",
    "Chattanooga",
    "Chesapeake",
    "Chicago",
    "Cincinnati",
    "Clearwater",
    "Cleveland",
    "Columbia",
    "Columbus",
    "Concord",
    "Coral-Springs",
    "Corona",
    "Costa-Mesa",
    "Dallas",
    "Dayton",
    "Denver",
    "Des-Moines",
    "Detroit",
    "Durham",
    "Edison",
    "El-Paso",
    "Elizabeth",
    "Elk-Grove",
    "Erie",
    "Escondido",
    "Eugene",
    "Evansville",
    "Everett",
    "Fairfield",
    "Fargo",
    "Fayetteville",
    "Flint",
    "Fontana",
    "Fort-Collins",
    "Fort-Lauderdale",
    "Fort-Wayne",
    "Fort-Worth",
    "Fremont",
    "Fresno",
    "Frisco",
    "Fullerton",
    "Gainesville",
    "Garden-Grove",
    "Garland",
    "Gilbert",
    "Glendale",
    "Grand-Prairie",
    "Grand-Rapids",
    "Greensboro",
    "Hampton",
    "Hartford",
    "Hayward",
    "Henderson",
    "Hialeah",
    "Hillsboro",
    "Hollywood",
    "Honolulu",
    "Houston",
    "Huntington",
    "Huntsville",
    "Independence",
    "Indianapolis",
    "Inglewood",
    "Irvine",
    "Irving",
    "Jackson",
    "Jacksonville",
    "Jersey-City",
    "Joliet",
    "Kansas-City",
    "Kent",
    "Killeen",
    "Knoxville",
    "Lafayette",
    "Lakeland",
    "Lakewood",
    "Lancaster",
    "Lansing",
    "Laredo",
    "Las-Vegas",
    "Lewisville",
    "Lexington",
    "Lincoln",
    "Little-Rock",
    "Long-Beach",
    "Los-Angeles",
    "Louisville",
    "Lowell",
    "Lubbock",
    "Lynchburg",
    "Madison",
    "Manchester",
    "McAllen",
    "McKinney",
    "Memphis",
    "Mesa",
    "Mesquite",
    "Miami",
    "Midland",
    "Milwaukee",
    "Minneapolis",
    "Miramar",
    "Mobile",
    "Modesto",
    "Montgomery",
    "Moreno-Valley",
    "Murfreesboro",
    "Murrieta",
    "Naperville",
    "Nashville",
    "New-Haven",
    "New-Orleans",
    "New-York",
    "Newark",
    "Newport",
    "Norfolk",
    "Norman",
    "North-Charleston",
    "Norwalk",
    "Oakland",
    "Oceanside",
    "Odessa",
    "Oklahoma-City",
    "Olathe",
    "Omaha",
    "Ontario",
    "Orange",
    "Orlando",
    "Overland-Park",
    "Oxnard",
    "Palm-Bay",
    "Palmdale",
    "Pasadena",
    "Paterson",
    "Pearland",
    "Pembroke-Pines",
    "Peoria",
    "Philadelphia",
    "Phoenix",
    "Pittsburgh",
    "Plano",
    "Pomona",
    "Pompano-Beach",
    "Port-St-Lucie",
    "Portland",
    "Providence",
    "Provo",
    "Pueblo",
    "Raleigh",
    "Rancho-Cucamonga",
    "Reno",
    "Richardson",
    "Richmond",
    "Riverside",
    "Rochester",
    "Rockford",
    "Roseville",
    "Round-Rock",
    "Sacramento",
    "Salem",
    "Salinas",
    "Salt-Lake-City",
    "San-Antonio",
    "San-Bernardino",
    "San-Diego",
    "San-Francisco",
    "San-Jose",
    "San-Mateo",
    "Sandy-Springs",
    "Santa-Ana",
    "Santa-Clara",
    "Santa-Clarita",
    "Santa-Maria",
    "Santa-Rosa",
    "Savannah",
    "Scottsdale",
    "Seattle",
    "Shreveport",
    "Simi-Valley",
    "Sioux-Falls",
    "South-Bend",
    "Spokane",
    "Springfield",
    "St-Louis",
    "St-Paul",
    "St-Petersburg",
    "Stamford",
    "Sterling-Heights",
    "Stockton",
    "Sunnyvale",
    "Surprise",
    "Syracuse",
    "Tacoma",
    "Tallahassee",
    "Tampa",
    "Temecula",
    "Tempe",
    "Thornton",
    "Thousand-Oaks",
    "Toledo",
    "Topeka",
    "Torrance",
    "Tucson",
    "Tulsa",
    "Tyler",
    "Vallejo",
    "Vancouver",
    "Ventura",
    "Victorville",
    "Virginia-Beach",
    "Visalia",
    "Waco",
    "Warren",
    "Washington",
    "Waterbury",
    "West-Covina",
    "West-Jordan",
    "West-Palm-Beach",
    "West-Valley-City",
    "Westminster",
    "Wichita",
    "Wichita-Falls",
    "Wilmington",
    "Winston-Salem",
    "Worcester",
    "Yonkers"
  ]

  @impl true
  def mount(%{"terminal_id" => terminal_id}, _session, socket) do
    terminal = ClaudeLive.TerminalManager.get_terminal(terminal_id)

    if terminal do
      ClaudeLive.TerminalManager.subscribe()

      worktree_terminals =
        if terminal.worktree_id do
          ClaudeLive.TerminalManager.list_worktree_terminals(terminal.worktree_id)
        else
          %{terminal_id => terminal}
        end

      all_terminals = ClaudeLive.TerminalManager.list_terminals()
      all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
      projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

      socket =
        socket
        |> assign(:terminal_id, terminal_id)
        |> assign(:terminal, terminal)
        |> assign(:session_id, terminal.session_id)
        |> assign(:subscribed, false)
        |> assign(:page_title, "Terminal - #{terminal.name}")
        |> assign(:global_terminals, ClaudeLive.TerminalManager.list_terminals())
        |> assign(:projects_with_terminals, projects_with_terminals)
        |> assign(:worktree_terminals, worktree_terminals)
        |> assign(:sidebar_collapsed, false)
        |> assign(:expanded_projects, MapSet.new())
        |> assign(:show_worktree_form, nil)
        |> assign(:new_worktree_forms, %{})
        |> push_event("load-sidebar-state", %{})
        |> push_event("load-expanded-projects", %{})

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Terminal not found")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("connect", %{"cols" => cols, "rows" => rows}, socket) do
    session_id = socket.assigns.session_id
    terminal = socket.assigns.terminal

    result =
      if ClaudeLive.Terminal.PtyServer.exists?(session_id) do
        unless socket.assigns.subscribed do
          try do
            ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())
          catch
            :exit, {:timeout, _} ->
              Logger.warning("Timeout subscribing to terminal #{session_id}, retrying...")
              Process.sleep(100)
              ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())
          end
        end

        case ClaudeLive.Terminal.PtyServer.get_buffer(session_id) do
          {:ok, buffer} ->
            Enum.each(buffer, fn data ->
              send(self(), {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}})
            end)

          _ ->
            :ok
        end

        ClaudeLive.Terminal.PtyServer.resize(session_id, cols, rows)
        :ok
      else
        case ClaudeLive.Terminal.Supervisor.start_terminal(session_id) do
          {:ok, _pid} ->
            # Give the server a moment to fully initialize
            Process.sleep(50)

            try do
              ClaudeLive.Terminal.PtyServer.subscribe(session_id, self())

              ClaudeLive.Terminal.PtyServer.spawn_shell(session_id,
                cols: cols,
                rows: rows,
                shell: System.get_env("SHELL", "/bin/bash"),
                cwd: terminal.worktree_path
              )

              :ok
            catch
              :exit, {:timeout, _} ->
                Logger.error("Failed to initialize terminal #{session_id} after starting")
                {:error, "Failed to connect to terminal. Please refresh the page."}
            end

          {:error, reason} ->
            Logger.error("Failed to start terminal #{session_id}: #{inspect(reason)}")
            {:error, "Failed to start terminal"}
        end
      end

    case result do
      :ok ->
        updated_terminal = Map.put(terminal, :connected, true)
        ClaudeLive.TerminalManager.upsert_terminal(socket.assigns.terminal_id, updated_terminal)
        {:noreply, socket |> assign(:subscribed, true) |> assign(:terminal, updated_terminal)}

      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign(:subscribed, false)}
    end
  end

  @impl true
  def handle_event("input", %{"data" => data}, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.write(socket.assigns.session_id, data)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("resize", %{"cols" => cols, "rows" => rows}, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.resize(socket.assigns.session_id, cols, rows)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("disconnect", _params, socket) do
    if socket.assigns.terminal.connected do
      ClaudeLive.Terminal.PtyServer.unsubscribe(socket.assigns.session_id, self())
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)
      updated_terminal = Map.put(socket.assigns.terminal, :connected, false)
      {:noreply, assign(socket, :terminal, updated_terminal)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open-in-iterm", _params, socket) do
    path = socket.assigns.terminal.worktree_path
    encoded_path = URI.encode(path)
    command = URI.encode("cd #{path} && claude code")
    iterm_url = "iterm2://app/command?d=#{encoded_path}&c=#{command}"

    {:noreply,
     socket
     |> push_event("open-url", %{url: iterm_url})
     |> put_flash(:info, "Opening in iTerm2...")}
  end

  @impl true
  def handle_event("open-in-zed", _params, socket) do
    path = socket.assigns.terminal.worktree_path

    case System.cmd("zed", [path], stderr_to_stdout: true) do
      {_output, 0} ->
        {:noreply, put_flash(socket, :info, "Opening in Zed...")}

      {_output, _status} ->
        zed_url = "zed://file/#{URI.encode(path)}"

        {:noreply,
         socket
         |> push_event("open-url", %{url: zed_url})
         |> put_flash(:info, "Opening in Zed...")}
    end
  end

  @impl true
  def handle_event("close-terminal", %{"terminal-id" => terminal_id}, socket) do
    case ClaudeLive.TerminalManager.delete_terminal(terminal_id) do
      :ok ->
        if terminal_id == socket.assigns.terminal_id do
          worktree_terminals =
            if socket.assigns.terminal.worktree_id do
              ClaudeLive.TerminalManager.list_worktree_terminals(
                socket.assigns.terminal.worktree_id
              )
            else
              %{}
            end

          if map_size(worktree_terminals) > 0 do
            {first_id, _} = Enum.at(worktree_terminals, 0)
            {:noreply, push_navigate(socket, to: ~p"/terminals/#{first_id}")}
          else
            remaining_terminals = ClaudeLive.TerminalManager.list_terminals()

            if map_size(remaining_terminals) > 0 do
              {first_id, _} = Enum.at(remaining_terminals, 0)
              {:noreply, push_navigate(socket, to: ~p"/terminals/#{first_id}")}
            else
              {:noreply, push_navigate(socket, to: ~p"/")}
            end
          end
        else
          updated_worktree_terminals =
            if socket.assigns.terminal.worktree_id do
              ClaudeLive.TerminalManager.list_worktree_terminals(
                socket.assigns.terminal.worktree_id
              )
            else
              socket.assigns.worktree_terminals
            end

          all_terminals = ClaudeLive.TerminalManager.list_terminals()
          all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
          projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

          {:noreply,
           socket
           |> assign(:global_terminals, ClaudeLive.TerminalManager.list_terminals())
           |> assign(:projects_with_terminals, projects_with_terminals)
           |> assign(:worktree_terminals, updated_worktree_terminals)}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Terminal not found")}
    end
  end

  @impl true
  def handle_event("new-terminal", _params, socket) do
    terminal = socket.assigns.terminal

    existing_numbers =
      socket.assigns.worktree_terminals
      |> Map.values()
      |> Enum.map(fn t ->
        case Regex.run(~r/Terminal (\d+)/, t.name) do
          [_, num] -> String.to_integer(num)
          _ -> 0
        end
      end)

    next_number =
      if Enum.empty?(existing_numbers) do
        1
      else
        Enum.max(existing_numbers) + 1
      end

    new_terminal_id = "#{terminal.worktree_id}-#{next_number}"
    new_session_id = "terminal-#{terminal.worktree_id}-#{next_number}"

    new_terminal = %{
      id: new_terminal_id,
      worktree_id: terminal.worktree_id,
      worktree_branch: terminal.worktree_branch,
      worktree_path: terminal.worktree_path,
      repository_id: terminal.repository_id,
      session_id: new_session_id,
      connected: false,
      name: "Terminal #{next_number}"
    }

    ClaudeLive.TerminalManager.upsert_terminal(new_terminal_id, new_terminal)

    {:noreply, push_navigate(socket, to: ~p"/terminals/#{new_terminal_id}")}
  end

  def handle_event("toggle-sidebar", _params, socket) do
    new_state = !socket.assigns.sidebar_collapsed

    {:noreply,
     socket
     |> assign(:sidebar_collapsed, new_state)
     |> push_event("store-sidebar-state", %{collapsed: new_state})}
  end

  def handle_event("sidebar-state-loaded", %{"collapsed" => collapsed}, socket) do
    {:noreply, assign(socket, :sidebar_collapsed, collapsed)}
  end

  def handle_event("toggle-project", %{"project-id" => project_id}, socket) do
    expanded_projects = socket.assigns.expanded_projects

    new_expanded =
      if MapSet.member?(expanded_projects, project_id) do
        MapSet.delete(expanded_projects, project_id)
      else
        MapSet.put(expanded_projects, project_id)
      end

    {:noreply,
     socket
     |> assign(:expanded_projects, new_expanded)
     |> push_event("store-expanded-projects", %{projects: MapSet.to_list(new_expanded)})}
  end

  def handle_event("expanded-projects-loaded", %{"projects" => projects}, socket) do
    {:noreply, assign(socket, :expanded_projects, MapSet.new(projects))}
  end

  def handle_event("new-worktree", %{"repository-id" => repository_id}, socket) do
    branch_name = generate_branch_name()

    form =
      ClaudeLive.Claude.Worktree
      |> AshPhoenix.Form.for_create(:create,
        params: %{
          repository_id: repository_id,
          branch: branch_name
        },
        as: "worktree"
      )
      |> to_form()

    new_forms = Map.put(socket.assigns.new_worktree_forms, repository_id, form)

    {:noreply,
     socket
     |> assign(:show_worktree_form, repository_id)
     |> assign(:new_worktree_forms, new_forms)}
  end

  def handle_event("cancel-new-worktree", %{"repository-id" => repository_id}, socket) do
    new_forms = Map.delete(socket.assigns.new_worktree_forms, repository_id)

    {:noreply,
     socket
     |> assign(:show_worktree_form, nil)
     |> assign(:new_worktree_forms, new_forms)}
  end

  def handle_event(
        "validate-worktree",
        %{"repository-id" => repository_id, "worktree" => params},
        socket
      ) do
    form = socket.assigns.new_worktree_forms[repository_id]
    validated_form = AshPhoenix.Form.validate(form.source, params) |> to_form()
    new_forms = Map.put(socket.assigns.new_worktree_forms, repository_id, validated_form)

    {:noreply, assign(socket, :new_worktree_forms, new_forms)}
  end

  def handle_event(
        "create-worktree",
        %{"repository-id" => repository_id, "worktree" => params},
        socket
      ) do
    params = Map.put(params, "repository_id", repository_id)
    form = socket.assigns.new_worktree_forms[repository_id]

    case AshPhoenix.Form.submit(form.source, params: params) do
      {:ok, worktree} ->
        all_terminals = ClaudeLive.TerminalManager.list_terminals()
        all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
        projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

        terminal_id = "#{worktree.id}-1"
        session_id = "terminal-#{worktree.id}-1"

        new_terminal = %{
          id: terminal_id,
          worktree_id: worktree.id,
          worktree_branch: worktree.branch,
          worktree_path: worktree.path,
          repository_id: worktree.repository_id,
          session_id: session_id,
          connected: false,
          name: "Terminal 1"
        }

        ClaudeLive.TerminalManager.upsert_terminal(terminal_id, new_terminal)
        new_forms = Map.delete(socket.assigns.new_worktree_forms, repository_id)

        {:noreply,
         socket
         |> assign(:projects_with_terminals, projects_with_terminals)
         |> assign(:show_worktree_form, nil)
         |> assign(:new_worktree_forms, new_forms)
         |> put_flash(:info, "Worktree '#{worktree.branch}' created successfully")
         |> push_navigate(to: ~p"/terminals/#{terminal_id}")}

      {:error, form} ->
        new_forms = Map.put(socket.assigns.new_worktree_forms, repository_id, to_form(form))
        {:noreply, assign(socket, :new_worktree_forms, new_forms)}
    end
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket) do
    if session_id == socket.assigns.session_id do
      {:noreply, push_event(socket, "terminal_output", %{data: data})}
    else
      Logger.warning(
        "Terminal #{socket.assigns.terminal_id} received data for wrong session: #{session_id}"
      )

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_exit, exit_code}},
        socket
      ) do
    if session_id == socket.assigns.session_id do
      Logger.info("Terminal #{socket.assigns.terminal_id} exited with code: #{exit_code}")
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)
      updated_terminal = Map.put(socket.assigns.terminal, :connected, false)

      {:noreply,
       socket
       |> assign(:terminal, updated_terminal)
       |> push_event("terminal_exit", %{code: exit_code})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {ClaudeLive.Terminal.PtyServer, session_id, {:terminal_closed, _status}},
        socket
      ) do
    if session_id == socket.assigns.session_id do
      ClaudeLive.TerminalManager.update_terminal_status(socket.assigns.terminal_id, false)
      updated_terminal = Map.put(socket.assigns.terminal, :connected, false)

      {:noreply,
       socket |> assign(:terminal, updated_terminal) |> push_event("terminal_closed", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:terminal_updated, {_updated_terminal_id, _}}, socket) do
    worktree_terminals =
      if socket.assigns.terminal.worktree_id do
        ClaudeLive.TerminalManager.list_worktree_terminals(socket.assigns.terminal.worktree_id)
      else
        socket.assigns.worktree_terminals
      end

    all_terminals = ClaudeLive.TerminalManager.list_terminals()
    all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
    projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

    {:noreply,
     socket
     |> assign(:worktree_terminals, worktree_terminals)
     |> assign(:projects_with_terminals, projects_with_terminals)}
  end

  @impl true
  def handle_info({:terminal_deleted, deleted_terminal_id}, socket) do
    updated_worktree_terminals =
      if socket.assigns.terminal.worktree_id do
        ClaudeLive.TerminalManager.list_worktree_terminals(socket.assigns.terminal.worktree_id)
      else
        socket.assigns.worktree_terminals
      end

    all_terminals = ClaudeLive.TerminalManager.list_terminals()
    all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
    projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

    updated_socket =
      socket
      |> assign(:global_terminals, ClaudeLive.TerminalManager.list_terminals())
      |> assign(:projects_with_terminals, projects_with_terminals)
      |> assign(:worktree_terminals, updated_worktree_terminals)

    if deleted_terminal_id == socket.assigns.terminal_id do
      if map_size(updated_worktree_terminals) > 0 do
        {first_id, _} = Enum.at(updated_worktree_terminals, 0)
        {:noreply, push_navigate(updated_socket, to: ~p"/terminals/#{first_id}")}
      else
        remaining_terminals = updated_socket.assigns.global_terminals

        if map_size(remaining_terminals) > 0 do
          {first_id, _} = Enum.at(remaining_terminals, 0)
          {:noreply, push_navigate(updated_socket, to: ~p"/terminals/#{first_id}")}
        else
          {:noreply, push_navigate(updated_socket, to: ~p"/")}
        end
      end
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_info({:ui_preference_updated, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:subscribed] && socket.assigns[:session_id] do
      try do
        ClaudeLive.Terminal.PtyServer.unsubscribe(socket.assigns.session_id, self())
      rescue
        _ -> :ok
      end
    end

    :ok
  end

  defp get_dashboard_link(terminal) do
    if terminal.worktree_id do
      case get_repository_id(terminal.worktree_id) do
        {:ok, repo_id} -> ~p"/dashboard/#{repo_id}"
        _ -> ~p"/"
      end
    else
      ~p"/"
    end
  end

  defp get_repository_id(worktree_id) do
    try do
      worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)
      {:ok, worktree.repository_id}
    rescue
      _ -> {:error, :not_found}
    end
  end

  defp get_repository_name(terminal) do
    if terminal.worktree_id do
      try do
        worktree = Ash.get!(ClaudeLive.Claude.Worktree, terminal.worktree_id, load: :repository)
        Path.basename(worktree.repository.path)
      rescue
        _ -> "Unknown Repository"
      end
    else
      "Unknown Repository"
    end
  end

  defp group_projects_and_terminals(repositories, terminals) do
    # First, get all worktrees with terminals
    worktrees_with_terminals =
      terminals
      |> Enum.group_by(fn {_id, terminal} ->
        {terminal.worktree_id, terminal.worktree_branch, terminal.worktree_path}
      end)
      |> Enum.map(fn {{worktree_id, branch, path}, grouped_terminals} ->
        terminal_map = Map.new(grouped_terminals)
        first_terminal = elem(hd(grouped_terminals), 1)

        %{
          worktree_id: worktree_id,
          branch: branch,
          path: path,
          repository_id: first_terminal.repository_id,
          terminals: terminal_map,
          terminal_count: map_size(terminal_map),
          has_connected: Enum.any?(terminal_map, fn {_id, t} -> t.connected end)
        }
      end)

    # Group worktrees by repository_id
    worktrees_by_repo =
      worktrees_with_terminals
      |> Enum.group_by(& &1.repository_id)

    # Now create a complete list of all projects, including those without terminals
    repositories
    |> Enum.map(fn repository ->
      project_worktrees = Map.get(worktrees_by_repo, repository.id, [])

      # Add worktrees from repository that don't have terminals yet
      all_worktrees =
        repository.worktrees
        |> Enum.map(fn worktree ->
          # Check if this worktree already has terminals
          existing = Enum.find(project_worktrees, fn w -> w.worktree_id == worktree.id end)

          if existing do
            existing
          else
            # Create a worktree entry without terminals
            %{
              worktree_id: worktree.id,
              branch: worktree.branch,
              path: worktree.path,
              repository_id: repository.id,
              terminals: %{},
              terminal_count: 0,
              has_connected: false
            }
          end
        end)

      # If repository has no worktrees at all, use the worktrees with terminals
      final_worktrees = if Enum.empty?(all_worktrees), do: project_worktrees, else: all_worktrees

      total_terminals =
        Enum.reduce(final_worktrees, 0, fn w, acc -> acc + w.terminal_count end)

      has_any_connected =
        Enum.any?(final_worktrees, fn w -> w.has_connected end)

      %{
        repository_id: repository.id,
        repository_name: repository.name,
        repository_path: repository.path,
        worktrees: Enum.sort_by(final_worktrees, & &1.branch),
        worktree_count: length(final_worktrees),
        total_terminal_count: total_terminals,
        has_connected: has_any_connected
      }
    end)
    |> Enum.sort_by(& &1.repository_name)
  end

  defp generate_branch_name do
    Enum.random(@us_cities) |> String.downcase()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="terminal-container"
      class="h-screen bg-gradient-to-br from-gray-900 via-gray-950 to-black flex"
      phx-hook="SidebarState"
    >
      <div id="expanded-projects-state" phx-hook="ExpandedProjectsState" class="hidden"></div>
      <div class={[
        "bg-gray-900/95 backdrop-blur-sm border-r border-gray-800/50 flex flex-col transition-all duration-300 ease-in-out overflow-hidden",
        if @sidebar_collapsed do
          "w-14"
        else
          "w-72"
        end
      ]}>
        <div class="border-b border-gray-800/50">
          <div class={[
            "transition-all duration-300",
            if @sidebar_collapsed do
              "p-3"
            else
              "p-6"
            end
          ]}>
            <div class="flex items-center justify-between">
              <%= unless @sidebar_collapsed do %>
                <div>
                  <h3 class="text-sm font-bold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent uppercase tracking-wider">
                    Projects
                  </h3>
                  <p class="text-xs text-gray-500 mt-2">
                    {length(@projects_with_terminals)} project(s)
                  </p>
                </div>
              <% end %>
              <button
                phx-click="toggle-sidebar"
                class={[
                  "flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-800/50 transition-colors text-gray-400 hover:text-gray-200",
                  if @sidebar_collapsed do
                    "mx-auto"
                  else
                    "flex-shrink-0"
                  end
                ]}
                title={if @sidebar_collapsed, do: "Expand sidebar", else: "Collapse sidebar"}
              >
                <.icon
                  name={if @sidebar_collapsed, do: "hero-chevron-right", else: "hero-chevron-left"}
                  class="w-4 h-4"
                />
              </button>
            </div>
          </div>
        </div>
        <div class="flex-1 overflow-y-auto overflow-x-hidden py-2">
          <%= if length(@projects_with_terminals) > 0 do %>
            <%= if @sidebar_collapsed do %>
              <%= for project <- @projects_with_terminals do %>
                <% first_terminal =
                  project.worktrees
                  |> Enum.find_value(fn w ->
                    case Enum.at(w.terminals, 0) do
                      {id, _terminal} -> id
                      _ -> nil
                    end
                  end) %>
                <div class="mx-2 mb-1 flex justify-center group relative">
                  <%= if first_terminal do %>
                    <.link
                      navigate={~p"/terminals/#{first_terminal}"}
                      class={[
                        "w-8 h-8 rounded-lg flex items-center justify-center transition-all duration-200 relative",
                        Enum.any?(project.worktrees, fn w ->
                          w.worktree_id == @terminal.worktree_id
                        end) &&
                          "bg-gradient-to-br from-blue-500 to-indigo-600 shadow-lg shadow-blue-950/20",
                        (!Enum.any?(project.worktrees, fn w ->
                           w.worktree_id == @terminal.worktree_id
                         end) &&
                           (project.has_connected && "bg-gradient-to-br from-blue-600 to-indigo-700")) ||
                          "bg-gradient-to-br from-gray-600 to-gray-700",
                        "hover:scale-105"
                      ]}
                      title={project.repository_name}
                    >
                      <.icon name="hero-building-office-2" class="w-4 h-4 text-white" />
                    </.link>
                  <% else %>
                    <div
                      class="w-8 h-8 rounded-lg flex items-center justify-center transition-all duration-200 relative bg-gradient-to-br from-gray-600 to-gray-700 hover:scale-105"
                      title={project.repository_name}
                    >
                      <.icon name="hero-building-office-2" class="w-4 h-4 text-white" />
                    </div>
                  <% end %>
                  <div class="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-40">
                    <div class="font-bold">{project.repository_name}</div>
                    <div class="text-gray-400">{project.worktree_count} worktree(s)</div>
                    <div class="text-gray-500">{project.total_terminal_count} terminal(s)</div>
                  </div>
                </div>
              <% end %>
            <% else %>
              <%= for project <- @projects_with_terminals do %>
                <div class="mx-2 mb-2">
                  <button
                    phx-click="toggle-project"
                    phx-value-project-id={project.repository_id || "unknown"}
                    class={[
                      "w-full px-3 py-2 rounded-lg flex items-center justify-between transition-all duration-200 hover:bg-gray-800/50 group",
                      Enum.any?(project.worktrees, fn w -> w.worktree_id == @terminal.worktree_id end) &&
                        "bg-gradient-to-r from-blue-950/30 to-indigo-950/30"
                    ]}
                  >
                    <div class="flex items-center space-x-2 flex-1 min-w-0">
                      <.icon
                        name={
                          if MapSet.member?(@expanded_projects, project.repository_id || "unknown") do
                            "hero-chevron-down"
                          else
                            "hero-chevron-right"
                          end
                        }
                        class="w-4 h-4 text-gray-400 flex-shrink-0"
                      />
                      <div class={[
                        "w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0",
                        (project.has_connected && "bg-gradient-to-br from-blue-500 to-indigo-600") ||
                          "bg-gradient-to-br from-gray-600 to-gray-700"
                      ]}>
                        <.icon name="hero-building-office-2" class="w-4 h-4 text-white" />
                      </div>
                      <div class="flex-1 min-w-0 text-left">
                        <div class={[
                          "text-sm font-bold truncate",
                          (project.has_connected && "text-white") || "text-gray-300"
                        ]}>
                          {project.repository_name}
                        </div>
                        <div class="text-xs text-gray-500">
                          {project.worktree_count} worktree{if project.worktree_count != 1, do: "s"}, {project.total_terminal_count} terminal{if project.total_terminal_count !=
                                                                                                                                                   1,
                                                                                                                                                 do:
                                                                                                                                                   "s"}
                        </div>
                      </div>
                    </div>
                    <span class={[
                      "w-2 h-2 rounded-full flex-shrink-0",
                      (project.has_connected && "bg-emerald-400 animate-pulse") || "bg-gray-600"
                    ]}>
                    </span>
                  </button>

                  <%= if MapSet.member?(@expanded_projects, project.repository_id || "unknown") do %>
                    <div class="ml-6 mt-1">
                      <%= for worktree <- project.worktrees do %>
                        <% first_terminal = Enum.at(worktree.terminals, 0) %>
                        <%= if first_terminal do %>
                          <% {first_terminal_id, _} = first_terminal %>
                          <div class={[
                            "mb-1 rounded-lg group relative transition-all duration-200 hover:bg-gray-800/50",
                            worktree.worktree_id == @terminal.worktree_id &&
                              "bg-gradient-to-r from-emerald-950/30 to-cyan-950/30"
                          ]}>
                            <.link
                              navigate={~p"/terminals/#{first_terminal_id}"}
                              class="block px-3 py-2 transition-all duration-200 rounded-lg overflow-hidden"
                            >
                              <div class="flex items-center space-x-2">
                                <div class={[
                                  "w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0",
                                  (worktree.has_connected &&
                                     "bg-gradient-to-br from-emerald-500 to-green-600") ||
                                    "bg-gradient-to-br from-gray-600 to-gray-700"
                                ]}>
                                  <.icon name="hero-folder-open" class="w-4 h-4 text-white" />
                                </div>
                                <div class="flex-1 min-w-0 overflow-hidden">
                                  <div class={[
                                    "text-sm font-medium truncate",
                                    (worktree.has_connected && "text-white") || "text-gray-300"
                                  ]}>
                                    {worktree.branch}
                                  </div>
                                  <div class="text-xs text-gray-500 truncate">
                                    {worktree.terminal_count} terminal{if worktree.terminal_count !=
                                                                            1,
                                                                          do: "s"}
                                  </div>
                                </div>
                                <span class={[
                                  "w-1.5 h-1.5 rounded-full flex-shrink-0",
                                  (worktree.has_connected && "bg-emerald-400 animate-pulse") ||
                                    "bg-gray-600"
                                ]}>
                                </span>
                              </div>
                            </.link>
                          </div>
                        <% else %>
                          <div class="mb-1 rounded-lg hover:bg-gray-800/50 transition-all duration-200">
                            <div class="px-3 py-2 flex items-center space-x-2">
                              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-gray-600 to-gray-700 flex items-center justify-center flex-shrink-0">
                                <.icon name="hero-folder-open" class="w-4 h-4 text-white" />
                              </div>
                              <div class="flex-1 min-w-0 overflow-hidden">
                                <div class="text-sm font-medium truncate text-gray-400">
                                  {worktree.branch}
                                </div>
                                <div class="text-xs text-gray-500 truncate">
                                  No terminals
                                </div>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      <% end %>

                      <%= if @show_worktree_form == project.repository_id do %>
                        <div class="mb-1 p-3 bg-gray-900/50 rounded-lg border border-gray-700/50">
                          <.form
                            for={@new_worktree_forms[project.repository_id]}
                            phx-submit="create-worktree"
                            phx-change="validate-worktree"
                            class="space-y-2"
                          >
                            <input type="hidden" name="repository-id" value={project.repository_id} />
                            <div>
                              <input
                                type="text"
                                name={@new_worktree_forms[project.repository_id][:branch].name}
                                value={@new_worktree_forms[project.repository_id][:branch].value}
                                class="w-full px-2 py-1 text-sm border border-gray-600 rounded bg-gray-800 text-gray-100 focus:outline-none focus:ring-1 focus:ring-emerald-500 focus:border-emerald-500"
                                placeholder="Branch name"
                                autofocus
                              />
                              <%= for error <- @new_worktree_forms[project.repository_id][:branch].errors do %>
                                <p class="mt-1 text-xs text-red-400">{error}</p>
                              <% end %>
                            </div>
                            <div class="flex space-x-2">
                              <button
                                type="submit"
                                class="flex-1 px-2 py-1 text-xs bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-700 hover:to-green-700 text-white font-medium rounded transition-all duration-200"
                              >
                                Create
                              </button>
                              <button
                                type="button"
                                phx-click="cancel-new-worktree"
                                phx-value-repository-id={project.repository_id}
                                class="flex-1 px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 font-medium rounded transition-all duration-200"
                              >
                                Cancel
                              </button>
                            </div>
                          </.form>
                        </div>
                      <% else %>
                        <button
                          phx-click="new-worktree"
                          phx-value-repository-id={project.repository_id}
                          class="w-full mb-1 px-3 py-2 flex items-center space-x-2 rounded-lg hover:bg-gray-800/50 transition-all duration-200 group"
                        >
                          <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center flex-shrink-0 group-hover:from-emerald-600 group-hover:to-green-600 transition-all duration-200">
                            <.icon
                              name="hero-plus"
                              class="w-4 h-4 text-gray-400 group-hover:text-white"
                            />
                          </div>
                          <span class="text-sm text-gray-500 group-hover:text-gray-300">
                            New Worktree
                          </span>
                        </button>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% end %>
          <% else %>
            <div class="px-4 py-12 text-center">
              <div class="w-16 h-16 rounded-full bg-gradient-to-br from-gray-700 to-gray-800 flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-folder" class="w-8 h-8 text-gray-500" />
              </div>
              <p class="text-sm font-medium text-gray-400">No workspaces open</p>
              <p class="text-xs text-gray-500 mt-2">Open a workspace from the dashboard</p>
            </div>
          <% end %>
        </div>
        <div class="border-t border-gray-800/50 p-4">
          <%= if @sidebar_collapsed do %>
            <.link
              navigate={get_dashboard_link(@terminal)}
              class="flex items-center justify-center w-8 h-8 mx-auto rounded-lg bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 transition-all duration-200"
              title="Back to Dashboard"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" />
            </.link>
          <% else %>
            <.link
              navigate={get_dashboard_link(@terminal)}
              class="flex items-center justify-center text-sm font-medium bg-gray-800/50 hover:bg-gray-700/50 text-gray-300 hover:text-gray-100 rounded-lg px-4 py-2 transition-all duration-200"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" />
              <span class="ml-2">Dashboard</span>
            </.link>
          <% end %>
        </div>
      </div>
      <div class="flex-1 flex flex-col">
        <div class="bg-gray-950 border-b border-gray-800/50">
          <div class="flex items-center">
            <div class="flex-1 flex items-center overflow-x-auto scrollbar-none">
              <%= for {tid, terminal} <- @worktree_terminals do %>
                <div class={[
                  "flex items-center border-r border-gray-800/50 hover:bg-gray-900/50 transition-all duration-200 min-w-fit group relative",
                  tid == @terminal_id && "bg-gray-900 border-b-2 border-b-emerald-500"
                ]}>
                  <.link navigate={~p"/terminals/#{tid}"} class="flex items-center px-4 py-2">
                    <div class="flex items-center space-x-2">
                      <span class={[
                        "inline-block w-2 h-2 rounded-full flex-shrink-0",
                        (terminal.connected && "bg-emerald-400 animate-pulse") || "bg-gray-600"
                      ]}>
                      </span>
                      <span class={[
                        "text-sm whitespace-nowrap",
                        (tid == @terminal_id && "text-white font-medium") || "text-gray-400"
                      ]}>
                        {terminal.name}
                      </span>
                    </div>
                  </.link>
                  <button
                    phx-click="close-terminal"
                    phx-value-terminal-id={tid}
                    class="ml-1 mr-2 p-0.5 rounded hover:bg-gray-700 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <.icon name="hero-x-mark" class="w-3 h-3 text-gray-500 hover:text-gray-300" />
                  </button>
                </div>
              <% end %>
              <button
                phx-click="new-terminal"
                class="flex items-center px-3 py-2 hover:bg-gray-900/50 transition-all duration-200 border-r border-gray-800/50 group"
                title="New Terminal"
              >
                <.icon name="hero-plus" class="w-4 h-4 text-gray-500 group-hover:text-gray-300" />
              </button>
            </div>
            <div class="flex items-center px-3 space-x-2">
              <button
                phx-click="open-in-iterm"
                class="flex items-center justify-center w-7 h-7 rounded hover:bg-gray-800/50 transition-colors"
                title="Open in iTerm2"
              >
                <svg
                  class="w-4 h-4 text-gray-500 hover:text-gray-300"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
              </button>
              <button
                phx-click="open-in-zed"
                class="flex items-center justify-center w-7 h-7 rounded hover:bg-gray-800/50 transition-colors"
                title="Open in Zed"
              >
                <svg
                  class="w-4 h-4 text-gray-500 hover:text-gray-300"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                  />
                </svg>
              </button>
              <.link
                navigate={~p"/git-diff/terminal-#{@terminal_id}"}
                class="flex items-center justify-center w-7 h-7 rounded hover:bg-gray-800/50 transition-colors"
                title="View git diffs"
              >
                <svg
                  class="w-4 h-4 text-gray-500 hover:text-gray-300"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                  />
                </svg>
              </.link>
            </div>
          </div>
        </div>
        <div class="bg-gray-900/80 backdrop-blur-sm px-6 py-3 border-b border-gray-800/50 flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
                <.icon name="hero-command-line" class="w-4 h-4 text-white" />
              </div>
              <div>
                <h2 class="text-white font-bold">{get_repository_name(@terminal)}</h2>
                <div class="flex items-center gap-2 text-xs">
                  <span class="text-emerald-400">{@terminal.worktree_branch}</span>
                  <span class="text-gray-600">•</span>
                  <span class="text-gray-500 truncate max-w-md">
                    {@terminal.worktree_path}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-2">
              <span class={[
                "inline-block w-2 h-2 rounded-full",
                (@terminal.connected &&
                   "bg-emerald-400 animate-pulse shadow-emerald-400/50 shadow-sm") || "bg-red-500"
              ]}>
              </span>
              <span class={[
                "text-sm font-medium",
                (@terminal.connected && "text-emerald-400") || "text-red-400"
              ]}>
                {if @terminal.connected, do: "Connected", else: "Disconnected"}
              </span>
            </div>
          </div>
        </div>

        <div class="flex-1 relative bg-black">
          <div
            phx-hook="SingleTerminalHook"
            id="terminal-area"
            data-terminal-id={@terminal_id}
            data-session-id={@session_id}
            class="h-full w-full"
          >
            <div id="terminals-container" phx-update="ignore" class="h-full w-full">
              <div id={"terminal-container-#{@terminal_id}"} class="h-full w-full">
                <div id={"terminal-#{@terminal_id}"} class="h-full w-full"></div>
              </div>
            </div>

            <button
              id="scroll-to-bottom"
              class="absolute bottom-6 right-6 hidden bg-gray-800/90 hover:bg-gray-700/90 text-white rounded-full p-3 shadow-lg backdrop-blur-sm border border-gray-600/50 transition-all duration-200 hover:scale-110 group"
              title="Scroll to bottom"
            >
              <svg
                class="w-5 h-5 group-hover:animate-bounce"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 14l-7 7m0 0l-7-7m7 7V3"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".OpenUrl">
      export default {
        mounted() {
          this.handleEvent("open-url", ({url}) => {
            window.location.href = url
          })
        }
      }
    </script>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ExpandedProjectsState">
      export default {
        mounted() {
          const stored = localStorage.getItem('expandedProjects')
          if (stored) {
            try {
              const projects = JSON.parse(stored)
              this.pushEvent("expanded-projects-loaded", {projects: projects})
            } catch (e) {
              console.error("Failed to parse expanded projects from localStorage", e)
            }
          }

          this.handleEvent("store-expanded-projects", ({projects}) => {
            localStorage.setItem('expandedProjects', JSON.stringify(projects))
          })

          this.handleEvent("load-expanded-projects", () => {
            const stored = localStorage.getItem('expandedProjects')
            if (stored) {
              try {
                const projects = JSON.parse(stored)
                this.pushEvent("expanded-projects-loaded", {projects: projects})
              } catch (e) {
                console.error("Failed to parse expanded projects from localStorage", e)
              }
            }
          })
        }
      }
    </script>
    """
  end
end
