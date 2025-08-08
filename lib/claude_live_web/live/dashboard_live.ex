defmodule ClaudeLiveWeb.DashboardLive do
  use ClaudeLiveWeb, :live_view
  require Ash.Query

  @us_cities [
    # Major cities
    "Phoenix",
    "Austin",
    "Seattle",
    "Denver",
    "Portland",
    "Miami",
    "Boston",
    "Atlanta",
    "Dallas",
    "Houston",
    "Chicago",
    "Detroit",
    "Memphis",
    "Nashville",
    "Orlando",
    "Tampa",
    "Charlotte",
    "Raleigh",
    "Richmond",
    "Buffalo",
    "Cleveland",
    "Pittsburgh",
    "Cincinnati",
    "Columbus",
    "Madison",
    "Milwaukee",
    "Minneapolis",
    "Omaha",
    "Wichita",
    "Tulsa",
    "Reno",
    "Tucson",
    "Salem",
    "Eugene",
    "Spokane",
    "Tacoma",
    "Oakland",
    "Fresno",
    "Sacramento",
    "Stockton",
    "Riverside",
    "Anaheim",
    "Mesa",
    "Aurora",
    "Chandler",
    "Gilbert",
    "Scottsdale",
    "Tempe",
    "Peoria",
    "Surprise",
    "Lakewood",
    "Thornton",
    "Westminster",
    "Arvada",
    "Berkeley",
    "Cambridge",
    "Somerville",
    "Quincy",
    "Lynn",
    "Lowell",
    "Springfield",
    "Worcester",
    "Medford",
    "Malden",
    "Revere",
    "Everett",
    "Arlington",
    "Bellevue",
    "Kent",
    "Renton",
    "Auburn",
    "Kirkland",
    "Redmond",

    # Additional cities
    "Akron",
    "Albany",
    "Albuquerque",
    "Alexandria",
    "Alhambra",
    "Allen",
    "Allentown",
    "Amarillo",
    "Ames",
    "Anchorage",
    "Antioch",
    "Appleton",
    "Arcadia",
    "Asheville",
    "Athens",
    "Augusta",
    "Bakersfield",
    "Baltimore",
    "Bangor",
    "Baton",
    "Baytown",
    "Beaumont",
    "Beaverton",
    "Bellingham",
    "Belmont",
    "Bend",
    "Bentonville",
    "Bethlehem",
    "Billings",
    "Birmingham",
    "Bismarck",
    "Bloomington",
    "Boca",
    "Boise",
    "Bolingbrook",
    "Bossier",
    "Boulder",
    "Bradenton",
    "Brandon",
    "Brentwood",
    "Bridgeport",
    "Bristol",
    "Brockton",
    "Broken",
    "Brooklyn",
    "Brownsville",
    "Bryan",
    "Buena",
    "Burbank",
    "Burlington",
    "Burnsville",
    "Caldwell",
    "Calexico",
    "Camden",
    "Canton",
    "Carlsbad",
    "Carmel",
    "Carson",
    "Casper",
    "Castle",
    "Cedar",
    "Centennial",
    "Ceres",
    "Cerritos",
    "Champaign",
    "Chapel",
    "Charleston",
    "Charlottesville",
    "Chattanooga",
    "Chelsea",
    "Chesapeake",
    "Cheyenne",
    "Chico",
    "Chino",
    "Chula",
    "Cicero",
    "Clarksville",
    "Clearwater",
    "Clifton",
    "Clinton",
    "Clovis",
    "Coachella",
    "Coconut",
    "Colton",
    "Columbia",
    "Concord",
    "Conroe",
    "Conway",
    "Coon",
    "Coral",
    "Corona",
    "Corpus",
    "Corvallis",
    "Costa",
    "Covina",
    "Cranston",
    "Crystal",
    "Culver",
    "Cumberland",
    "Cupertino",
    "Cutler",
    "Cypress",
    "Daly",
    "Danbury",
    "Danville",
    "Davenport",
    "Davie",
    "Davis",
    "Dayton",
    "Dearborn",
    "Decatur",
    "Deerfield",
    "Delano",
    "Delray",
    "Deltona",
    "Denton",
    "Derby",
    "Destin",
    "Diamond",
    "Doral",
    "Dothan",
    "Dover",
    "Downey",
    "Draper",
    "Dublin",
    "Dubuque",
    "Duluth",
    "Duncan",
    "Dunwoody",
    "Durham",
    "Eagan",
    "Eagle",
    "Easton",
    "Edina",
    "Edmond",
    "Edmonds",
    "Elizabeth",
    "Elkhart",
    "Elmhurst",
    "Elmira",
    "Encinitas",
    "Enid",
    "Erie",
    "Escondido",
    "Euclid",
    "Evanston",
    "Evansville",
    "Fairbanks",
    "Fairfield",
    "Fargo",
    "Farmington",
    "Fayetteville",
    "Findlay",
    "Fishers",
    "Flagstaff",
    "Flint",
    "Florence",
    "Florissant",
    "Folsom",
    "Fontana",
    "Franklin",
    "Frederick",
    "Fremont",
    "Frisco",
    "Fullerton",
    "Gainesville",
    "Galveston",
    "Gardena",
    "Garden",
    "Garfield",
    "Garland",
    "Gary",
    "Gastonia",
    "Georgetown",
    "Germantown",
    "Glendale",
    "Glendora",
    "Glenview",
    "Goodyear",
    "Granada",
    "Granbury",
    "Grandview",
    "Grapevine",
    "Greeley",
    "Greensboro",
    "Greenville",
    "Greenwich",
    "Gresham",
    "Griffin",
    "Groton",
    "Gulfport",
    "Hackensack",
    "Hagerstown",
    "Hallandale",
    "Hamilton",
    "Hammond",
    "Hampton",
    "Hanover",
    "Harlingen",
    "Harrisburg",
    "Hartford",
    "Hattiesburg",
    "Haverhill",
    "Hawthorne",
    "Hayward",
    "Helena",
    "Henderson",
    "Hendersonville",
    "Hialeah",
    "Highland",
    "Hillsboro",
    "Hilo",
    "Hilton",
    "Hoboken",
    "Hoffman",
    "Hollywood",
    "Homestead",
    "Honolulu",
    "Hoover",
    "Hopkins",
    "Hopkinsville",
    "Hudson",
    "Huntington",
    "Huntsville",
    "Independence",
    "Indianapolis",
    "Indio",
    "Inglewood",
    "Irvine",
    "Irving",
    "Jackson",
    "Jacksonville",
    "Jamestown",
    "Janesville",
    "Jefferson",
    "Jenks",
    "Jersey",
    "Johnson",
    "Joliet",
    "Jonesboro",
    "Jupiter",
    "Kalamazoo",
    "Kaneohe",
    "Kankakee",
    "Kansas",
    "Katy",
    "Kearny",
    "Keizer",
    "Kenner",
    "Kennewick",
    "Kenosha",
    "Kettering",
    "Killeen",
    "Kingsport",
    "Kingston",
    "Kissimmee",
    "Knoxville",
    "Kokomo",
    "Lafayette",
    "Laguna",
    "Lancaster",
    "Lansing",
    "Laredo",
    "Largo",
    "Lawrence",
    "Lawton",
    "Layton",
    "League",
    "Leander",
    "Lenexa",
    "Lewisville",
    "Lexington",
    "Liberty",
    "Lincoln",
    "Linden",
    "Littleton",
    "Livermore",
    "Livonia",
    "Lombard",
    "Lompoc",
    "Longmont",
    "Longview",
    "Louisville",
    "Loveland",
    "Lubbock",
    "Lynchburg",
    "Macon",
    "Madera",
    "Manchester",
    "Manhattan",
    "Manitowoc",
    "Mankato",
    "Mansfield",
    "Maple",
    "Margate",
    "Marietta",
    "Marion",
    "Marlborough",
    "Marysville",
    "Mason",
    "Massillon",
    "Maui",
    "McAllen",
    "McKinney",
    "Meadows",
    "Melbourne",
    "Mentor",
    "Merced",
    "Meriden",
    "Meridian",
    "Metairie",
    "Methuen",
    "Metuchen",
    "Middleton",
    "Middletown",
    "Midland",
    "Midwest",
    "Milford",
    "Millcreek",
    "Milpitas",
    "Milton",
    "Miramar",
    "Mishawaka",
    "Mission",
    "Missoula",
    "Mobile",
    "Modesto",
    "Moline",
    "Monroe",
    "Monrovia",
    "Montclair",
    "Montebello",
    "Monterey",
    "Montgomery",
    "Montrose",
    "Moorhead",
    "Moorpark",
    "Moreno",
    "Morgan",
    "Morristown",
    "Morton",
    "Mountain",
    "Muncie",
    "Murfreesboro",
    "Murray",
    "Murrieta",
    "Muskegon",
    "Muskogee",
    "Nampa",
    "Napa",
    "Naperville",
    "Naples",
    "Nashua",
    "Newark",
    "Newcastle",
    "Newport",
    "Newton",
    "Niagara",
    "Noblesville",
    "Norfolk",
    "Normal",
    "Norman",
    "Northbrook",
    "Northglenn",
    "Norwalk",
    "Norwich",
    "Novato",
    "Novi",
    "Ocala",
    "Oceanside",
    "Odessa",
    "Ogden",
    "Oklahoma",
    "Olathe",
    "Olympia",
    "Ontario",
    "Orange",
    "Orem",
    "Orland",
    "Ormond",
    "Oshkosh",
    "Overland",
    "Owensboro",
    "Oxford",
    "Oxnard",
    "Pacifica",
    "Paducah",
    "Palatine",
    "Palestine",
    "Palmer",
    "Palmetto",
    "Palmdale",
    "Palo",
    "Panama",
    "Paradise",
    "Paramount",
    "Parker",
    "Parkersburg",
    "Parma",
    "Pasadena",
    "Pasco",
    "Passaic",
    "Paterson",
    "Pawtucket",
    "Peabody",
    "Pearl",
    "Pearland",
    "Pembroke",
    "Pensacola",
    "Petaluma",
    "Pflugerville",
    "Pharr",
    "Philadelphia",
    "Phillipsburg",
    "Phoenix",
    "Pickerington",
    "Pico",
    "Pierre",
    "Pike",
    "Pinellas",
    "Pittsburg",
    "Pittsfield",
    "Placerville",
    "Plainfield",
    "Plano",
    "Plantation",
    "Plattsburgh",
    "Plymouth",
    "Pocatello",
    "Pomona",
    "Pompano",
    "Pontiac",
    "Portage",
    "Portsmouth",
    "Potomac",
    "Poughkeepsie",
    "Powell",
    "Prescott",
    "Princeton",
    "Providence",
    "Provo",
    "Pueblo",
    "Pullman",
    "Puyallup",
    "Quakertown",
    "Queens",
    "Racine",
    "Radcliff",
    "Rahway",
    "Raleigh",
    "Ramsey",
    "Rancho",
    "Randolph",
    "Rapid",
    "Reading",
    "Redding",
    "Redlands",
    "Redondo",
    "Redwood",
    "Reedley",
    "Reston",
    "Revere",
    "Rexburg",
    "Reynoldsburg",
    "Richardson",
    "Richland",
    "Richmond",
    "Ridgewood",
    "Riverbank",
    "Riverdale",
    "Riverton",
    "Roanoke",
    "Rochester",
    "Rockford",
    "Rocklin",
    "Rockport",
    "Rockville",
    "Rockwall",
    "Rogers",
    "Rohnert",
    "Rome",
    "Romeoville",
    "Roseburg",
    "Rosemead",
    "Roseville",
    "Roswell",
    "Rotterdam",
    "Round",
    "Rowlett",
    "Royal",
    "Ruskin",
    "Russellville",
    "Rutherford",
    "Rutland",
    "Saginaw",
    "Salem",
    "Salina",
    "Salinas",
    "Salisbury",
    "Sammamish",
    "Sanford",
    "Santee",
    "Sarasota",
    "Saratoga",
    "Savannah",
    "Sayreville",
    "Schaumburg",
    "Schenectady",
    "Scotch",
    "Scotia",
    "Scranton",
    "Seabrook",
    "Seaford",
    "Seaside",
    "Secaucus",
    "Sedona",
    "Seguin",
    "Seminole",
    "Shaker",
    "Shakopee",
    "Shamrock",
    "Shawnee",
    "Sheboygan",
    "Shelby",
    "Shelton",
    "Sherman",
    "Sherwood",
    "Shoreline",
    "Shreveport",
    "Sidney",
    "Sierra",
    "Signal",
    "Silverdale",
    "Simi",
    "Simpsonville",
    "Sioux",
    "Skokie",
    "Smyrna",
    "Snellville",
    "Somerset",
    "Sonoma",
    "Southaven",
    "Southfield",
    "Southgate",
    "Sparks",
    "Spartanburg",
    "Speedway",
    "Spencer",
    "Spokane",
    "Springdale",
    "Springfield",
    "Stafford",
    "Stamford",
    "Stanton",
    "Sterling",
    "Stillwater",
    "Stockbridge",
    "Stoneham",
    "Stonington",
    "Stoughton",
    "Stratford",
    "Streamwood",
    "Strongsville",
    "Stuart",
    "Studio",
    "Sturgeon",
    "Suffolk",
    "Summerville",
    "Summit",
    "Sumter",
    "Sunbury",
    "Sunnyvale",
    "Sunrise",
    "Sunset",
    "Superior",
    "Swansea",
    "Sycamore",
    "Syracuse",
    "Tallahassee",
    "Tamarac",
    "Tampa",
    "Taunton",
    "Taylor",
    "Temecula",
    "Temple",
    "Tenafly",
    "Terre",
    "Tewksbury",
    "Texarkana",
    "Texas",
    "The",
    "Thornton",
    "Thousand",
    "Tigard",
    "Tinley",
    "Titusville",
    "Toledo",
    "Toms",
    "Tonawanda",
    "Topeka",
    "Torrance",
    "Torrington",
    "Tracy",
    "Trenton",
    "Troy",
    "Trumbull",
    "Tucker",
    "Tulare",
    "Tullahoma",
    "Tupelo",
    "Turlock",
    "Tuscaloosa",
    "Tustin",
    "Twin",
    "Tyler",
    "Union",
    "University",
    "Upland",
    "Urbana",
    "Urbandale",
    "Utica",
    "Vacaville",
    "Valdosta",
    "Valencia",
    "Vallejo",
    "Valley",
    "Valparaiso",
    "Vancouver",
    "Venice",
    "Ventura",
    "Vernon",
    "Vero",
    "Victoria",
    "Victorville",
    "Vienna",
    "Vineland",
    "Virginia",
    "Visalia",
    "Vista",
    "Waco",
    "Waipahu",
    "Wakefield",
    "Waldorf",
    "Walker",
    "Wallingford",
    "Walnut",
    "Walpole",
    "Waltham",
    "Warminster",
    "Warner",
    "Warren",
    "Warrenville",
    "Warrington",
    "Warsaw",
    "Warwick",
    "Washington",
    "Waterbury",
    "Waterford",
    "Waterloo",
    "Watertown",
    "Waterville",
    "Watsonville",
    "Waukegan",
    "Waukesha",
    "Wausau",
    "Wauwatosa",
    "Waycross",
    "Wayne",
    "Webster",
    "Wellesley",
    "Wellington",
    "Wells",
    "Wenatchee",
    "Westborough",
    "Westbrook",
    "Westchester",
    "Westerly",
    "Westfield",
    "Westford",
    "Westhampton",
    "Westlake",
    "Westland",
    "Westmont",
    "Weston",
    "Westport",
    "Westwood",
    "Wethersfield",
    "Weymouth",
    "Wheaton",
    "Wheeler",
    "Wheeling",
    "Whittier",
    "Wilkes",
    "Williamsburg",
    "Williamson",
    "Williamsport",
    "Williamstown",
    "Willoughby",
    "Willow",
    "Wilmette",
    "Wilmington",
    "Wilson",
    "Wilton",
    "Winchester",
    "Windham",
    "Windsor",
    "Winfield",
    "Winnetka",
    "Winona",
    "Winston",
    "Winter",
    "Winthrop",
    "Woburn",
    "Woodbridge",
    "Woodbury",
    "Woodinville",
    "Woodland",
    "Woodstock",
    "Woonsocket",
    "Wooster",
    "Worthington",
    "Wyandotte",
    "Wylie",
    "Wyoming",
    "Yakima",
    "Yarmouth",
    "Yonkers",
    "Yorba",
    "York",
    "Yorktown",
    "Youngstown",
    "Ypsilanti",
    "Yuba",
    "Yucca",
    "Yuma",
    "Zachary",
    "Zanesville"
  ]

  @impl true
  def mount(_params, _session, socket) do
    repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)

    socket =
      socket
      |> assign(:repositories, repositories)
      |> assign(:selected_repository, nil)
      |> assign(:worktrees, [])
      |> assign(:show_new_worktree_form, false)
      |> assign(:new_worktree_form, nil)
      |> assign(:page_title, "Claude Live Dashboard")
      |> assign(:collapsed_worktrees, MapSet.new())
      |> push_event("load-collapsed-worktrees", %{})

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"repo_id" => repo_id}, _uri, socket) do
    repository = Ash.get!(ClaudeLive.Claude.Repository, repo_id)
    worktrees = load_worktrees(repository)

    socket =
      socket
      |> assign(:selected_repository, repository)
      |> assign(:worktrees, worktrees)
      |> assign(:show_new_worktree_form, false)
      |> assign(:new_worktree_form, nil)

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-950"
      id="dashboard"
      phx-hook="DashboardHooks"
    >
      <!-- Sidebar -->
      <div class="w-72 bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm shadow-xl border-r border-gray-200/50 dark:border-gray-800 flex flex-col">
        <div class="p-6 border-b border-gray-200/50 dark:border-gray-800">
          <h2 class="text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 dark:from-blue-400 dark:to-indigo-400 bg-clip-text text-transparent">
            Repositories
          </h2>
          <.link
            navigate={~p"/dashboard/browse/directory"}
            class="mt-3 inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200"
          >
            <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4">
              </path>
            </svg>
            Add repository
          </.link>
        </div>

        <div class="flex-1 overflow-y-auto py-2">
          <%= for repo <- @repositories do %>
            <div class={[
              "mx-2 mb-1 rounded-lg group relative transition-all duration-200",
              @selected_repository && @selected_repository.id == repo.id &&
                "bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/50 dark:to-indigo-950/50 shadow-sm"
            ]}>
              <.link
                patch={~p"/dashboard/#{repo.id}"}
                class="block px-4 py-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-all duration-200"
              >
                <div class="flex items-center">
                  <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center mr-3">
                    <.icon name="hero-folder" class="w-5 h-5 text-white" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="font-semibold text-gray-900 dark:text-gray-100">{repo.name}</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400 truncate">{repo.path}</div>
                  </div>
                </div>
              </.link>
              <button
                phx-click="remove-repository"
                phx-value-id={repo.id}
                class="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-all duration-200 p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/50 cursor-pointer"
                data-confirm="Remove this repository from the list?"
                title="Remove repository"
              >
                <.icon name="hero-trash" class="w-4 h-4 text-red-500 dark:text-red-400" />
              </button>
            </div>
          <% end %>
        </div>
        
    <!-- Terminal View Navigation in Sidebar -->
        <% total_terminals = Map.values(@global_terminals) |> length() %>
        <%= if total_terminals > 0 && length(@repositories) > 0 do %>
          <div class="p-4 border-t border-gray-200/50 dark:border-gray-800">
            <h3 class="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-3">
              Active Terminals ({total_terminals})
            </h3>
            <div class="space-y-2">
              <%= for {terminal_id, terminal} <- @global_terminals do %>
                <.link
                  navigate={~p"/terminals/#{terminal_id}"}
                  class="flex items-center justify-between p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                >
                  <div class="flex items-center space-x-2">
                    <span class={[
                      "w-2 h-2 rounded-full",
                      (terminal.connected && "bg-emerald-400 animate-pulse") || "bg-gray-400"
                    ]}>
                    </span>
                    <span class="text-sm text-gray-700 dark:text-gray-300">{terminal.name}</span>
                  </div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    {terminal.worktree_branch}
                  </span>
                </.link>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Main Content -->
      <div class="flex-1 overflow-hidden">
        <%= if @selected_repository do %>
          <div class="h-full flex flex-col">
            <!-- Header -->
            <div class="bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm shadow-lg border-b border-gray-200/50 dark:border-gray-800 px-8 py-6">
              <div class="flex items-center justify-between">
                <div>
                  <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-gray-100 dark:to-gray-300 bg-clip-text text-transparent">
                    {@selected_repository.name}
                  </h1>
                  <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                    {@selected_repository.path}
                  </p>
                </div>
                <div class="flex items-center gap-3">
                  <button
                    phx-click="new-worktree"
                    class="inline-flex items-center px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-medium rounded-lg shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 cursor-pointer"
                  >
                    <.icon name="hero-plus" class="w-5 h-5" />
                    <span class="ml-2">New Worktree</span>
                  </button>
                </div>
              </div>
            </div>
            
    <!-- Worktrees List -->
            <div class="flex-1 overflow-y-auto p-8">
              <%= if @show_new_worktree_form do %>
                <div class="mb-6 bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm rounded-xl shadow-xl border border-gray-200/50 dark:border-gray-800 p-6">
                  <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100 mb-4">
                    Create New Worktree
                  </h3>
                  <.form
                    for={@new_worktree_form}
                    phx-submit="create-worktree"
                    phx-change="validate-worktree"
                    class="space-y-4"
                  >
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Branch Name
                      </label>
                      <input
                        type="text"
                        name={@new_worktree_form[:branch].name}
                        value={@new_worktree_form[:branch].value}
                        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-800 dark:text-gray-100"
                        placeholder="Enter branch name"
                      />
                      <%= for error <- @new_worktree_form[:branch].errors do %>
                        <p class="mt-1 text-sm text-red-600 dark:text-red-400">{error}</p>
                      <% end %>
                    </div>
                    <div class="flex gap-3">
                      <button
                        type="submit"
                        class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-medium rounded-lg shadow-sm hover:shadow-md transition-all duration-200"
                      >
                        Create Worktree
                      </button>
                      <button
                        type="button"
                        phx-click="cancel-new-worktree"
                        class="inline-flex items-center px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 font-medium rounded-lg transition-all duration-200"
                      >
                        Cancel
                      </button>
                    </div>
                  </.form>
                </div>
              <% end %>

              <div class="grid grid-cols-1 gap-4">
                <%= for worktree <- @worktrees do %>
                  <div class="bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm rounded-xl shadow-lg hover:shadow-xl border border-gray-200/50 dark:border-gray-800 transition-all duration-300">
                    <!-- Worktree Header -->
                    <div class="p-6 pb-4">
                      <div class="flex items-start justify-between">
                        <div class="flex items-start flex-1">
                          <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-green-500 to-emerald-600 flex items-center justify-center mr-3 flex-shrink-0">
                            <.icon name="hero-code-bracket" class="w-5 h-5 text-white" />
                          </div>
                          <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-3">
                              <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100">
                                {worktree.branch}
                              </h3>
                              <%= if worktree.path do %>
                                <div class="flex items-center gap-1">
                                  <button
                                    phx-click="open-in-iterm"
                                    phx-value-path={worktree.path}
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
                                      >
                                      </path>
                                    </svg>
                                  </button>
                                  <button
                                    phx-click="open-in-zed"
                                    phx-value-path={worktree.path}
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
                                      >
                                      </path>
                                    </svg>
                                  </button>
                                  <.link
                                    navigate={~p"/git-diff/#{worktree.id}?expand=true"}
                                    class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                                    title="View git diffs"
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
                                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                                      />
                                    </svg>
                                  </.link>
                                  <div class="w-px h-6 bg-gray-200 dark:bg-gray-700 mx-1"></div>
                                  <% has_terminals =
                                    length(get_worktree_terminals(@global_terminals, worktree.id)) > 0 %>
                                  <button
                                    phx-click="delete-worktree"
                                    phx-value-id={worktree.id}
                                    data-confirm={
                                      unless has_terminals,
                                        do: "Are you sure? This will delete the git worktree."
                                    }
                                    disabled={has_terminals}
                                    class={[
                                      "flex items-center justify-center w-8 h-8 rounded-lg transition-colors",
                                      if has_terminals do
                                        "opacity-50 cursor-not-allowed bg-gray-50 dark:bg-gray-900"
                                      else
                                        "hover:bg-red-50 dark:hover:bg-red-950/30 cursor-pointer"
                                      end
                                    ]}
                                    title={
                                      if has_terminals,
                                        do: "Close all terminals before deleting",
                                        else: "Delete worktree"
                                    }
                                  >
                                    <.icon
                                      name="hero-trash"
                                      class={"w-4 h-4 #{if has_terminals, do: "text-gray-400 dark:text-gray-600", else: "text-red-500 dark:text-red-400"}"}
                                    />
                                  </button>
                                </div>
                              <% else %>
                                <div class="flex items-center gap-1">
                                  <span class="text-xs text-amber-600 dark:text-amber-500 px-2 py-1 bg-amber-50 dark:bg-amber-950/30 rounded">
                                    Failed to create
                                  </span>
                                  <button
                                    phx-click="delete-worktree"
                                    phx-value-id={worktree.id}
                                    data-confirm="Remove this failed worktree?"
                                    class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors cursor-pointer"
                                    title="Remove failed worktree"
                                  >
                                    <.icon
                                      name="hero-trash"
                                      class="w-4 h-4 text-red-500 dark:text-red-400"
                                    />
                                  </button>
                                </div>
                              <% end %>
                            </div>
                            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1 truncate">
                              {worktree.path || "Creating..."}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                    
    <!-- Terminals for this worktree -->
                    <!-- Terminals Section -->
                    <% worktree_terminals = get_worktree_terminals(@global_terminals, worktree.id) %>
                    <div class="border-t border-gray-200/50 dark:border-gray-800">
                      <div class="px-6 py-4">
                        <div class="flex items-center justify-between mb-3">
                          <div class="flex items-center gap-2">
                            <button
                              phx-click="toggle-worktree"
                              phx-value-worktree-id={worktree.id}
                              class="p-0.5 rounded hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                              title={
                                if MapSet.member?(@collapsed_worktrees, worktree.id),
                                  do: "Expand terminals",
                                  else: "Collapse terminals"
                              }
                            >
                              <.icon
                                name={
                                  if MapSet.member?(@collapsed_worktrees, worktree.id),
                                    do: "hero-chevron-right",
                                    else: "hero-chevron-down"
                                }
                                class="w-3 h-3 text-gray-500 dark:text-gray-400"
                              />
                            </button>
                            <span class="text-xs font-bold text-gray-600 dark:text-gray-400 uppercase tracking-wider">
                              Terminals
                            </span>
                          </div>
                          <span class="text-xs text-gray-500 dark:text-gray-500">
                            {length(worktree_terminals)} active
                          </span>
                        </div>

                        <%= unless MapSet.member?(@collapsed_worktrees, worktree.id) do %>
                          <%= if worktree_terminals == [] do %>
                            <div class="flex flex-col items-center justify-center py-6 bg-gray-50/50 dark:bg-gray-800/30 rounded-lg border border-dashed border-gray-300 dark:border-gray-700">
                              <.icon name="hero-command-line" class="w-6 h-6 text-gray-400 mb-2" />
                              <p class="text-sm text-gray-500 dark:text-gray-400 mb-3">
                                No active terminals
                              </p>
                              <button
                                phx-click="create_terminal"
                                phx-value-worktree_id={worktree.id}
                                class="inline-flex items-center px-4 py-2 text-sm font-medium bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white rounded-lg shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer"
                              >
                                <.icon name="hero-plus" class="w-4 h-4" />
                                <span class="ml-2">Create Terminal</span>
                              </button>
                            </div>
                          <% else %>
                            <div class="grid grid-cols-1 gap-2 mb-3">
                              <%= for terminal <- worktree_terminals do %>
                                <div class="group flex items-center justify-between bg-gray-50 dark:bg-gray-800/50 rounded-lg px-3 py-2.5 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all duration-200">
                                  <.link
                                    navigate={~p"/terminals/#{terminal.id}"}
                                    class="flex items-center flex-1 min-w-0 cursor-pointer"
                                  >
                                    <span class={[
                                      "inline-block w-2 h-2 rounded-full mr-3 flex-shrink-0",
                                      (terminal.connected && "bg-emerald-500 animate-pulse") ||
                                        "bg-gray-400"
                                    ]}>
                                    </span>
                                    <.icon
                                      name="hero-command-line"
                                      class="w-4 h-4 mr-2 text-gray-600 dark:text-gray-400 flex-shrink-0"
                                    />
                                    <span class="font-medium text-gray-800 dark:text-gray-200 truncate">
                                      {terminal.name}
                                    </span>
                                    <span class="ml-auto text-xs text-gray-500 dark:text-gray-400 pl-2">
                                      {(terminal.connected && "Connected") || "Disconnected"}
                                    </span>
                                  </.link>
                                  <.icon
                                    name="hero-arrow-right"
                                    class="w-4 h-4 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300 ml-2"
                                  />
                                </div>
                              <% end %>
                            </div>
                            <button
                              phx-click="create_terminal"
                              phx-value-worktree_id={worktree.id}
                              class="w-full inline-flex items-center justify-center px-3 py-2 text-xs font-medium bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg transition-all duration-200 cursor-pointer"
                            >
                              <.icon name="hero-plus" class="w-3 h-3 mr-1.5" /> Add Terminal
                            </button>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>

                <%= if @worktrees == [] do %>
                  <div class="flex flex-col items-center justify-center py-16">
                    <div class="w-20 h-20 rounded-full bg-gradient-to-br from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-800 flex items-center justify-center mb-4">
                      <.icon
                        name="hero-folder-plus"
                        class="w-10 h-10 text-gray-500 dark:text-gray-400"
                      />
                    </div>
                    <p class="text-lg font-medium text-gray-600 dark:text-gray-400">
                      No worktrees yet
                    </p>
                    <p class="text-sm text-gray-500 dark:text-gray-500 mt-1">
                      Create one to get started!
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% else %>
          <div class="h-full flex items-center justify-center">
            <div class="text-center">
              <div class="w-24 h-24 rounded-full bg-gradient-to-br from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-800 flex items-center justify-center mx-auto mb-6">
                <.icon name="hero-folder" class="w-12 h-12 text-gray-500 dark:text-gray-400" />
              </div>
              <p class="text-xl font-medium text-gray-600 dark:text-gray-400">Select a repository</p>
              <p class="text-sm text-gray-500 dark:text-gray-500 mt-2">
                Choose a repository from the sidebar to manage worktrees
              </p>
            </div>
          </div>
        <% end %>
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

  @impl true
  def handle_event("new-worktree", _params, socket) do
    # Generate a unique branch name using US city names
    branch_name = generate_branch_name()

    form =
      ClaudeLive.Claude.Worktree
      |> AshPhoenix.Form.for_create(:create,
        params: %{
          repository_id: socket.assigns.selected_repository.id,
          branch: branch_name
        },
        as: "worktree"
      )
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_new_worktree_form, true)
     |> assign(:new_worktree_form, form)}
  end

  def handle_event("cancel-new-worktree", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_new_worktree_form, false)
     |> assign(:new_worktree_form, nil)}
  end

  def handle_event("validate-worktree", %{"worktree" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.new_worktree_form.source, params) |> to_form()
    {:noreply, assign(socket, :new_worktree_form, form)}
  end

  def handle_event("create-worktree", %{"worktree" => params}, socket) do
    params = Map.put(params, "repository_id", socket.assigns.selected_repository.id)

    case AshPhoenix.Form.submit(socket.assigns.new_worktree_form.source, params: params) do
      {:ok, _worktree} ->
        worktrees = load_worktrees(socket.assigns.selected_repository)

        {:noreply,
         socket
         |> assign(:worktrees, worktrees)
         |> assign(:show_new_worktree_form, false)
         |> assign(:new_worktree_form, nil)
         |> put_flash(:info, "Worktree created successfully")}

      {:error, form} ->
        {:noreply, assign(socket, :new_worktree_form, to_form(form))}
    end
  end

  def handle_event("delete-worktree", %{"id" => id}, socket) do
    worktree = Ash.get!(ClaudeLive.Claude.Worktree, id)

    # Allow deletion if worktree has no path (failed creation) or no active terminals
    worktree_terminals = get_worktree_terminals(socket.assigns.global_terminals, id)

    cond do
      # Failed worktree (no path) - always allow deletion
      is_nil(worktree.path) ->
        case Ash.destroy(worktree) do
          :ok ->
            worktrees = load_worktrees(socket.assigns.selected_repository)

            {:noreply,
             socket
             |> assign(:worktrees, worktrees)
             |> put_flash(:info, "Failed worktree removed successfully")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to remove worktree")}
        end

      # Has active terminals - prevent deletion
      length(worktree_terminals) > 0 ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Cannot delete worktree with #{length(worktree_terminals)} active terminal(s). Please close all terminals first."
         )}

      # Normal worktree with no terminals - allow deletion
      true ->
        case Ash.destroy(worktree) do
          :ok ->
            worktrees = load_worktrees(socket.assigns.selected_repository)

            {:noreply,
             socket
             |> assign(:worktrees, worktrees)
             |> put_flash(:info, "Worktree deleted successfully")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to delete worktree")}
        end
    end
  end

  def handle_event("open-in-iterm", %{"path" => path}, socket) do
    encoded_path = URI.encode(path)
    command = URI.encode("cd #{path} && claude code")
    iterm_url = "iterm2://app/command?d=#{encoded_path}&c=#{command}"

    {:noreply,
     socket
     |> push_event("open-url", %{url: iterm_url})
     |> put_flash(:info, "Opening in iTerm2...")}
  end

  def handle_event("open-in-zed", %{"path" => path}, socket) do
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

  def handle_event("toggle-worktree", %{"worktree-id" => worktree_id}, socket) do
    collapsed_worktrees = socket.assigns.collapsed_worktrees

    updated_collapsed =
      if MapSet.member?(collapsed_worktrees, worktree_id) do
        MapSet.delete(collapsed_worktrees, worktree_id)
      else
        MapSet.put(collapsed_worktrees, worktree_id)
      end

    {:noreply,
     socket
     |> assign(:collapsed_worktrees, updated_collapsed)
     |> push_event("store-collapsed-worktrees", %{collapsed: MapSet.to_list(updated_collapsed)})}
  end

  def handle_event("collapsed-worktrees-loaded", %{"collapsed" => collapsed_list}, socket) do
    collapsed_set = MapSet.new(collapsed_list || [])
    {:noreply, assign(socket, :collapsed_worktrees, collapsed_set)}
  end

  def handle_event("create_terminal", %{"worktree_id" => worktree_id}, socket) do
    terminal_number = find_next_terminal_number(socket.assigns.global_terminals, worktree_id)
    terminal_id = "#{worktree_id}-#{terminal_number}"
    session_id = "terminal-#{worktree_id}-#{terminal_number}"
    worktree = Ash.get!(ClaudeLive.Claude.Worktree, worktree_id, load: :repository)

    terminal = %{
      id: terminal_id,
      worktree_id: worktree_id,
      worktree_branch: worktree.branch,
      worktree_path: worktree.path,
      repository_id: worktree.repository_id,
      session_id: session_id,
      connected: false,
      terminal_data: "",
      name: "Terminal #{terminal_number}"
    }

    ClaudeLive.TerminalManager.upsert_terminal(terminal_id, terminal)

    {:noreply,
     socket
     |> put_flash(:info, "Terminal created. Go to Terminal view to connect.")
     |> push_navigate(to: ~p"/terminals/#{terminal_id}")}
  end

  def handle_event("remove-repository", %{"id" => repo_id}, socket) do
    case Ash.destroy(Ash.get!(ClaudeLive.Claude.Repository, repo_id)) do
      :ok ->
        repositories = Ash.read!(ClaudeLive.Claude.Repository, load: :worktrees)

        selected_repository =
          if socket.assigns.selected_repository &&
               socket.assigns.selected_repository.id == repo_id do
            nil
          else
            socket.assigns.selected_repository
          end

        {:noreply,
         socket
         |> assign(:repositories, repositories)
         |> assign(:selected_repository, selected_repository)
         |> assign(:worktrees, [])
         |> push_navigate(to: ~p"/")
         |> put_flash(:info, "Repository removed successfully")}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to remove repository")}
    end
  end

  defp load_worktrees(repository) do
    repository
    |> Ash.load!(worktrees: :sessions)
    |> Map.get(:worktrees, [])
    |> Enum.sort_by(fn worktree ->
      # Worktrees without paths (being created) come first
      # Then sort by inserted_at (newest first)
      if is_nil(worktree.path) do
        {0, DateTime.to_unix(worktree.inserted_at || DateTime.utc_now())}
      else
        {1, -DateTime.to_unix(worktree.inserted_at || DateTime.utc_now())}
      end
    end)
  end

  defp get_worktree_terminals(global_terminals, worktree_id) do
    global_terminals
    |> Map.values()
    |> Enum.filter(fn terminal -> terminal.worktree_id == worktree_id end)
    |> Enum.sort_by(& &1.name)
  end

  defp generate_branch_name do
    Enum.random(@us_cities) |> String.downcase()
  end

  defp find_next_terminal_number(terminals, worktree_id) do
    existing_numbers =
      terminals
      |> Enum.filter(fn {_id, terminal} -> terminal.worktree_id == worktree_id end)
      |> Enum.map(fn {terminal_id, _terminal} ->
        case String.split(terminal_id, "-") do
          parts when length(parts) >= 2 ->
            case Integer.parse(List.last(parts)) do
              {num, ""} -> num
              _ -> nil
            end

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort()

    case existing_numbers do
      [] -> 1
      numbers -> find_first_gap(numbers, 1)
    end
  end

  defp find_first_gap([], current), do: current

  defp find_first_gap([num | rest], current) when num == current do
    find_first_gap(rest, current + 1)
  end

  defp find_first_gap([_num | _rest], current), do: current
end
