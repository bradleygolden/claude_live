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
  def mount(params, _session, socket) do
    case params do
      %{"terminal_id" => terminal_id} ->
        mount_with_terminal(terminal_id, socket)

      _ ->
        mount_without_terminal(socket)
    end
  end

  defp mount_with_terminal(terminal_id, socket) do
    terminal = ClaudeLive.TerminalManager.get_terminal(terminal_id)

    if terminal do
      ClaudeLive.TerminalManager.subscribe()

      if terminal.worktree_id do
        Phoenix.PubSub.subscribe(
          ClaudeLive.PubSub,
          "claude_events:created:#{terminal.worktree_id}"
        )
      end

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
        |> assign(:show_add_repo_dropdown, false)
        |> assign(:show_archived, false)
        |> assign(:claude_terminal_visible, false)
        |> assign(:has_notifications, false)
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

  defp mount_without_terminal(socket) do
    all_terminals = ClaudeLive.TerminalManager.list_terminals()
    all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
    projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

    first_terminal =
      case Map.keys(all_terminals) do
        [first_id | _] -> first_id
        [] -> nil
      end

    if first_terminal do
      {:ok, push_navigate(socket, to: ~p"/terminals/#{first_terminal}")}
    else
      socket =
        socket
        |> assign(:terminal_id, nil)
        |> assign(:terminal, nil)
        |> assign(:session_id, nil)
        |> assign(:subscribed, false)
        |> assign(:page_title, "Terminal")
        |> assign(:global_terminals, all_terminals)
        |> assign(:projects_with_terminals, projects_with_terminals)
        |> assign(:worktree_terminals, %{})
        |> assign(:sidebar_collapsed, false)
        |> assign(:expanded_projects, MapSet.new())
        |> assign(:show_worktree_form, nil)
        |> assign(:new_worktree_forms, %{})
        |> assign(:show_add_repo_dropdown, false)
        |> assign(:show_archived, false)
        |> assign(:claude_terminal_visible, false)
        |> assign(:has_notifications, false)
        |> push_event("load-sidebar-state", %{})
        |> push_event("load-expanded-projects", %{})

      {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "connect",
        %{"cols" => cols, "rows" => rows, "terminal_id" => "claude-terminal"},
        socket
      ) do
    require Logger
    Logger.info("Claude terminal connect event received: cols=#{cols}, rows=#{rows}")

    # Start a claude terminal process
    claude_session_id =
      socket.assigns[:claude_session_id] || "claude-#{System.unique_integer([:positive])}"

    Logger.info("Starting Claude terminal with session_id: #{claude_session_id}")

    # Start the Claude command in the project directory using Terminal Supervisor
    result =
      ClaudeLive.Terminal.Supervisor.start_terminal(claude_session_id,
        path: "/Users/bradleygolden/Development/bradleygolden/claude_live"
      )

    Logger.info("Terminal supervisor result: #{inspect(result)}")

    case result do
      {:ok, _pid} ->
        ClaudeLive.Terminal.PtyServer.subscribe(claude_session_id, self())

        # Spawn the claude shell
        ClaudeLive.Terminal.PtyServer.spawn_shell(claude_session_id,
          cols: cols,
          rows: rows,
          shell: "claude",
          cwd: "/Users/bradleygolden/Development/bradleygolden/claude_live"
        )

        {:noreply,
         socket
         |> assign(:claude_session_id, claude_session_id)
         |> push_event("claude_output", %{data: "Starting Claude terminal...\r\n"})}

      {:error, {:already_started, _pid}} ->
        ClaudeLive.Terminal.PtyServer.subscribe(claude_session_id, self())
        {:noreply, socket}

      {:error, reason} ->
        {:noreply,
         push_event(socket, "claude_output", %{
           data: "Failed to start Claude: #{inspect(reason)}\r\n"
         })}
    end
  end

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

  def handle_event("expanded-projects-loaded", %{"expandedProjects" => expanded_list}, socket) do
    expanded_set = MapSet.new(expanded_list)
    {:noreply, assign(socket, :expanded_projects, expanded_set)}
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
     |> push_event("store-expanded-projects", %{expandedProjects: MapSet.to_list(new_expanded)})}
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

  def handle_event("create-terminal-for-worktree", %{"worktree-id" => worktree_id}, socket) do
    worktree_info =
      socket.assigns.projects_with_terminals
      |> Enum.flat_map(& &1.worktrees)
      |> Enum.find(&(&1.worktree_id == worktree_id))

    if worktree_info do
      terminal_id = "#{worktree_id}-1"
      session_id = "terminal-#{worktree_id}-1"

      new_terminal = %{
        id: terminal_id,
        worktree_id: worktree_id,
        worktree_branch: worktree_info.branch,
        worktree_path: worktree_info.path,
        repository_id: worktree_info.repository_id,
        session_id: session_id,
        connected: false,
        name: "Terminal 1"
      }

      ClaudeLive.TerminalManager.upsert_terminal(terminal_id, new_terminal)

      {:noreply,
       socket
       |> put_flash(:info, "Terminal created for '#{worktree_info.branch}'")
       |> push_navigate(to: ~p"/terminals/#{terminal_id}")}
    else
      {:noreply, put_flash(socket, :error, "Worktree not found")}
    end
  end

  @impl true
  def handle_event("toggle-add-repo-dropdown", _params, socket) do
    {:noreply, assign(socket, :show_add_repo_dropdown, !socket.assigns.show_add_repo_dropdown)}
  end

  def handle_event("close-add-repo-dropdown", _params, socket) do
    {:noreply, assign(socket, :show_add_repo_dropdown, false)}
  end

  def handle_event("claude_disconnect", _params, socket) do
    if claude_session_id = socket.assigns[:claude_session_id] do
      ClaudeLive.Terminal.PtyServer.unsubscribe(claude_session_id, self())
      # Note: We don't stop the terminal here, just unsubscribe
      # The terminal will be cleaned up by the supervisor if needed
    end

    {:noreply, socket |> assign(:claude_session_id, nil)}
  end

  def handle_event("input", %{"data" => data, "terminal_id" => "claude-terminal"}, socket) do
    if claude_session_id = socket.assigns[:claude_session_id] do
      ClaudeLive.Terminal.PtyServer.write(claude_session_id, data)
    end

    {:noreply, socket}
  end

  def handle_event(
        "resize",
        %{"cols" => cols, "rows" => rows, "terminal_id" => "claude-terminal"},
        socket
      ) do
    if claude_session_id = socket.assigns[:claude_session_id] do
      ClaudeLive.Terminal.PtyServer.resize(claude_session_id, cols, rows)
    end

    {:noreply, socket}
  end

  def handle_event("toggle-archived", _params, socket) do
    require Ash.Query

    show_archived = !socket.assigns.show_archived

    all_terminals = ClaudeLive.TerminalManager.list_terminals()

    all_repositories =
      if show_archived do
        repositories = Ash.read!(ClaudeLive.Claude.Repository)

        Enum.map(repositories, fn repo ->
          # Read both active and archived worktrees
          all_worktrees =
            ClaudeLive.Claude.Worktree
            |> Ash.Query.filter(repository_id == ^repo.id)
            |> Ash.read!(action: :with_archived)

          Map.put(repo, :worktrees, all_worktrees)
        end)
      else
        Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
      end

    projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

    {:noreply,
     socket
     |> assign(:show_archived, show_archived)
     |> assign(:projects_with_terminals, projects_with_terminals)}
  end

  def handle_event("restore-worktree", %{"worktree-id" => worktree_id}, socket) do
    try do
      worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, action: :archived)

      case Ash.update(worktree, action: :unarchive) do
        {:ok, _restored} ->
          all_terminals = ClaudeLive.TerminalManager.list_terminals()

          all_repositories =
            if socket.assigns.show_archived do
              repositories = Ash.read!(ClaudeLive.Claude.Repository)

              Enum.map(repositories, fn repo ->
                all_worktrees =
                  Ash.read!(ClaudeLive.Claude.Worktree,
                    action: :with_archived,
                    filter: [repository_id: repo.id]
                  )

                Map.put(repo, :worktrees, all_worktrees)
              end)
            else
              Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
            end

          projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

          {:noreply,
           socket
           |> assign(:projects_with_terminals, projects_with_terminals)
           |> put_flash(:info, "Worktree '#{worktree.branch}' has been restored")}

        {:error, error} ->
          {:noreply, put_flash(socket, :error, "Failed to restore worktree: #{inspect(error)}")}
      end
    rescue
      _ ->
        {:noreply, put_flash(socket, :error, "Failed to restore worktree")}
    end
  end

  def handle_event("archive-worktree", %{"worktree-id" => worktree_id}, socket) do
    try do
      worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id)

      case Ash.destroy(worktree) do
        :ok ->
          all_terminals = ClaudeLive.TerminalManager.list_terminals()
          all_repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)
          projects_with_terminals = group_projects_and_terminals(all_repositories, all_terminals)

          current_worktree_id =
            if socket.assigns[:terminal] && socket.assigns.terminal[:worktree_id] do
              socket.assigns.terminal.worktree_id
            else
              nil
            end

          if current_worktree_id == worktree_id do
            {:noreply,
             socket
             |> put_flash(:info, "Worktree '#{worktree.branch}' has been archived")
             |> push_navigate(to: ~p"/")}
          else
            {:noreply,
             socket
             |> assign(:projects_with_terminals, projects_with_terminals)
             |> assign(:global_terminals, all_terminals)
             |> put_flash(:info, "Worktree '#{worktree.branch}' has been archived")}
          end

        {:error, error} ->
          {:noreply, put_flash(socket, :error, "Failed to archive worktree: #{inspect(error)}")}
      end
    rescue
      _ ->
        {:noreply, put_flash(socket, :error, "Worktree not found")}
    end
  end

  def handle_event("dismiss-notifications", _params, socket) do
    {:noreply, assign(socket, :has_notifications, false)}
  end

  @impl true
  def handle_info({ClaudeLive.Terminal.PtyServer, session_id, {:terminal_data, data}}, socket) do
    cond do
      session_id == socket.assigns[:claude_session_id] ->
        # This is data for the Claude terminal
        {:noreply, push_event(socket, "claude_output", %{data: data})}

      session_id == socket.assigns.session_id ->
        # This is data for the regular terminal
        {:noreply, push_event(socket, "terminal_output", %{data: data})}

      true ->
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
  def handle_info(%Ash.Notifier.Notification{data: event, action: %{name: :from_webhook}}, socket) do
    if event.event_type == :notification do
      Logger.info("Received Claude notification event for worktree #{event.worktree_id}")
      {:noreply, assign(socket, :has_notifications, true)}
    else
      Logger.debug("Received Claude event: #{event.event_type}")
      {:noreply, socket}
    end
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

  defp get_repository_name(terminal) do
    if terminal.worktree_id do
      try do
        worktree =
          case Ash.get(ClaudeLive.Claude.Worktree, terminal.worktree_id, load: :repository) do
            {:ok, wt} ->
              wt

            {:error, _} ->
              case Ash.get(ClaudeLive.Claude.Worktree, terminal.worktree_id,
                     action: :with_archived,
                     load: :repository
                   ) do
                {:ok, wt} -> wt
                {:error, _} -> nil
              end
          end

        if worktree && worktree.repository do
          Path.basename(worktree.repository.path)
        else
          "Unknown Repository"
        end
      rescue
        _ -> "Unknown Repository"
      end
    else
      "Unknown Repository"
    end
  end

  defp group_projects_and_terminals(repositories, terminals) do
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
          has_connected: Enum.any?(terminal_map, fn {_id, t} -> t.connected end),
          archived_at: nil
        }
      end)

    worktrees_by_repo =
      worktrees_with_terminals
      |> Enum.group_by(& &1.repository_id)

    repositories
    |> Enum.map(fn repository ->
      project_worktrees = Map.get(worktrees_by_repo, repository.id, [])

      all_worktrees =
        repository.worktrees
        |> Enum.map(fn worktree ->
          existing = Enum.find(project_worktrees, fn w -> w.worktree_id == worktree.id end)

          if existing do
            Map.put(existing, :archived_at, Map.get(worktree, :archived_at))
          else
            %{
              worktree_id: worktree.id,
              branch: worktree.display_name || worktree.branch,
              path: worktree.path,
              repository_id: repository.id,
              terminals: %{},
              terminal_count: 0,
              has_connected: false,
              archived_at: Map.get(worktree, :archived_at)
            }
          end
        end)

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
                  <div class="flex items-center gap-3 mt-2">
                    <p class="text-xs text-gray-500">
                      {length(@projects_with_terminals)} project(s)
                    </p>
                    <button
                      phx-click="toggle-archived"
                      class={[
                        "text-xs px-2 py-0.5 rounded transition-all",
                        if @show_archived do
                          "bg-amber-900/50 text-amber-400 hover:bg-amber-800/50"
                        else
                          "bg-gray-800/50 text-gray-400 hover:bg-gray-700/50"
                        end
                      ]}
                      title={if @show_archived, do: "Hide archived", else: "Show archived"}
                    >
                      {if @show_archived, do: "Hide Archived", else: "Show Archived"}
                    </button>
                  </div>
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
          <%= unless @sidebar_collapsed do %>
            <div class="mx-2 mb-2 relative" phx-click-away="close-add-repo-dropdown">
              <button
                phx-click="toggle-add-repo-dropdown"
                class="w-full px-3 py-2 rounded-lg flex items-center justify-between transition-all duration-200 hover:bg-gray-800/50 group border border-dashed border-gray-700 hover:border-gray-600"
                title="Add Repository"
              >
                <div class="flex items-center space-x-2">
                  <div class="w-8 h-8 rounded-lg flex items-center justify-center bg-gradient-to-br from-gray-700 to-gray-800">
                    <.icon name="hero-plus" class="w-4 h-4 text-gray-400" />
                  </div>
                  <div class="text-sm font-medium text-gray-400">Add Repository</div>
                </div>
              </button>
              <%= if assigns[:show_add_repo_dropdown] do %>
                <div class="absolute left-0 right-0 mt-2 bg-gray-800 rounded-lg shadow-xl border border-gray-700 z-50">
                  <.link
                    navigate={~p"/repositories/add/local"}
                    class="flex items-center gap-3 px-4 py-3 hover:bg-gray-700/50 transition-colors text-gray-300 hover:text-gray-100 rounded-t-lg"
                  >
                    <.icon name="hero-folder-open" class="w-5 h-5 text-gray-400" />
                    <div>
                      <div class="text-sm font-medium">Add Local Repository</div>
                      <div class="text-xs text-gray-500">Browse for existing Git repo</div>
                    </div>
                  </.link>
                  <.link
                    navigate={~p"/repositories/add/github"}
                    class="flex items-center gap-3 px-4 py-3 hover:bg-gray-700/50 transition-colors text-gray-300 hover:text-gray-100 rounded-b-lg border-t border-gray-700"
                  >
                    <svg class="w-5 h-5 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                    </svg>
                    <div>
                      <div class="text-sm font-medium">Clone from GitHub</div>
                      <div class="text-xs text-gray-500">Clone a remote repository</div>
                    </div>
                  </.link>
                </div>
              <% end %>
            </div>
          <% end %>
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
                      @terminal &&
                        Enum.any?(project.worktrees, fn w ->
                          w.worktree_id == @terminal.worktree_id
                        end) &&
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
                    <span
                      phx-click={
                        if @has_notifications &&
                             Enum.any?(project.worktrees, &(&1.worktree_id == @terminal.worktree_id)) do
                          "dismiss-notifications"
                        else
                          nil
                        end
                      }
                      class={[
                        "w-2 h-2 rounded-full flex-shrink-0",
                        if(
                          @has_notifications &&
                            Enum.any?(project.worktrees, &(&1.worktree_id == @terminal.worktree_id)),
                          do: "cursor-pointer"
                        ),
                        cond do
                          @has_notifications &&
                              Enum.any?(project.worktrees, &(&1.worktree_id == @terminal.worktree_id)) ->
                            "bg-blue-400 animate-pulse"

                          project.has_connected ->
                            "bg-emerald-400 animate-pulse"

                          true ->
                            "bg-gray-600"
                        end
                      ]}
                      title={
                        if @has_notifications &&
                             Enum.any?(project.worktrees, &(&1.worktree_id == @terminal.worktree_id)) do
                          "Click to dismiss Claude notifications"
                        else
                          nil
                        end
                      }
                    >
                    </span>
                  </button>

                  <%= if MapSet.member?(@expanded_projects, project.repository_id || "unknown") do %>
                    <div class="ml-6 mt-1">
                      <%= for worktree <- project.worktrees do %>
                        <%= if worktree.archived_at do %>
                          <!-- Archived worktree -->
                          <div class="mb-1 rounded-lg bg-gray-900/50 border border-gray-800 opacity-60 hover:opacity-80 transition-all duration-200 group relative">
                            <div class="px-3 py-2 flex items-center space-x-2">
                              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-gray-600 to-gray-700 flex items-center justify-center flex-shrink-0">
                                <.icon name="hero-archive-box" class="w-4 h-4 text-gray-400" />
                              </div>
                              <div class="flex items-center gap-2 flex-1">
                                <div class="flex-1 min-w-0 overflow-hidden">
                                  <div class="text-sm font-medium truncate text-gray-500 line-through">
                                    {worktree.branch}
                                  </div>
                                  <div class="text-xs text-gray-600">
                                    Archived
                                  </div>
                                </div>
                                <span class="text-xs text-amber-400 px-2 py-0.5 bg-amber-900/30 rounded">
                                  Archived
                                </span>
                              </div>
                            </div>
                            <!-- Restore button on hover -->
                            <button
                              phx-click="restore-worktree"
                              phx-value-worktree-id={worktree.worktree_id}
                              class="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 p-1 rounded-md bg-gray-700/80 hover:bg-emerald-600/80 text-gray-300 hover:text-white z-10"
                              title="Restore worktree"
                            >
                              <.icon name="hero-arrow-uturn-left" class="w-3 h-3" />
                            </button>
                          </div>
                        <% else %>
                          <% first_terminal = Enum.at(worktree.terminals, 0) %>
                          <%= if first_terminal do %>
                            <% {first_terminal_id, _} = first_terminal %>
                            <div class={[
                              "mb-1 rounded-lg group relative transition-all duration-200 hover:bg-gray-800/50",
                              worktree.worktree_id == @terminal.worktree_id &&
                                "bg-gradient-to-r from-emerald-950/30 to-cyan-950/30"
                            ]}>
                              <button
                                phx-click="archive-worktree"
                                phx-value-worktree-id={worktree.worktree_id}
                                class="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 p-1 rounded-md bg-gray-700/80 hover:bg-red-600/80 text-gray-300 hover:text-white z-20"
                                title="Archive worktree"
                              >
                                <.icon name="hero-archive-box" class="w-3 h-3" />
                              </button>
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
                            <div class="mb-1 rounded-lg hover:bg-gray-800/50 transition-all duration-200 group relative">
                              <button
                                phx-click="archive-worktree"
                                phx-value-worktree-id={worktree.worktree_id}
                                class="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 p-1 rounded-md bg-gray-700/80 hover:bg-red-600/80 text-gray-300 hover:text-white z-20"
                                title="Archive worktree"
                              >
                                <.icon name="hero-archive-box" class="w-3 h-3" />
                              </button>
                              <button
                                phx-click="create-terminal-for-worktree"
                                phx-value-worktree-id={worktree.worktree_id}
                                class="w-full px-3 py-2 flex items-center space-x-2 text-left"
                              >
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
                              </button>
                            </div>
                          <% end %>
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
                                <p class="mt-1 text-xs text-red-400">
                                  {case error do
                                    {message, _opts} -> message
                                    message when is_binary(message) -> message
                                    _ -> to_string(error)
                                  end}
                                </p>
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
      </div>
      <div class="flex-1 flex flex-col">
        <div class="bg-gray-900/80 backdrop-blur-sm px-6 py-3 border-b border-gray-800/50 flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
                <.icon name="hero-command-line" class="w-4 h-4 text-white" />
              </div>
              <%= if @terminal do %>
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
              <% else %>
                <div>
                  <h2 class="text-white font-bold">No Terminal Selected</h2>
                  <div class="text-xs text-gray-500">
                    Select a terminal from the sidebar or create a new one
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <%= if @terminal do %>
              <div class="flex items-center space-x-2">
                <a
                  href={"iterm2://app/command?d=#{URI.encode(@terminal.worktree_path)}&c=#{URI.encode("cd #{@terminal.worktree_path} && claude code")}"}
                  class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
                  title="Open in iTerm2"
                >
                  <svg
                    class="w-4 h-4 text-gray-500 dark:text-gray-400"
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
                </a>
                <button
                  phx-click="open-in-zed"
                  class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
                  title="Open in Zed"
                >
                  <svg
                    class="w-4 h-4 text-gray-500 dark:text-gray-400"
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
            <% end %>
          </div>
        </div>
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
    """
  end
end
