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
    repositories = Ash.read!(ClaudeLive.Claude.Repository)

    socket =
      socket
      |> assign(:repositories, repositories)
      |> assign(:selected_repository, nil)
      |> assign(:worktrees, [])
      |> assign(:show_new_worktree_form, false)
      |> assign(:new_worktree_form, nil)
      |> assign(:page_title, "Claude Live Dashboard")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"repo_id" => repo_id}, _uri, socket) do
    repository = Ash.get!(ClaudeLive.Claude.Repository, repo_id)
    worktrees = load_worktrees(repository)

    {:noreply,
     socket
     |> assign(:selected_repository, repository)
     |> assign(:worktrees, worktrees)
     |> assign(:show_new_worktree_form, false)
     |> assign(:new_worktree_form, nil)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-50 dark:bg-gray-900" id="dashboard" phx-hook=".OpenUrl">
      <!-- Sidebar -->
      <div class="w-64 bg-white dark:bg-gray-800 shadow-md">
        <div class="p-4 border-b dark:border-gray-700">
          <h2 class="text-lg font-semibold text-gray-800 dark:text-gray-200">Repositories</h2>
          <.link
            navigate={~p"/dashboard/browse/directory"}
            class="mt-2 text-sm text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 cursor-pointer block"
          >
            + Add repository
          </.link>
        </div>

        <div class="overflow-y-auto">
          <%= for repo <- @repositories do %>
            <div class={[
              "px-4 py-3 border-b dark:border-gray-700 group relative",
              @selected_repository && @selected_repository.id == repo.id &&
                "bg-blue-50 dark:bg-gray-700 border-blue-200 dark:border-blue-600"
            ]}>
              <.link
                patch={~p"/dashboard/#{repo.id}"}
                class="block hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer -mx-4 px-4 py-2 rounded"
              >
                <div class="font-medium text-gray-900 dark:text-gray-100">{repo.name}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400 truncate">{repo.path}</div>
              </.link>
              <button
                phx-click="remove-repository"
                phx-value-id={repo.id}
                class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300 p-1"
                data-confirm="Remove this repository from the list?"
                title="Remove repository"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="flex-1 overflow-hidden">
        <%= if @selected_repository do %>
          <div class="h-full flex flex-col">
            <!-- Header -->
            <div class="bg-white dark:bg-gray-800 shadow px-6 py-4">
              <div class="flex items-center justify-between">
                <div>
                  <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                    {@selected_repository.name}
                  </h1>
                  <p class="text-sm text-gray-500 dark:text-gray-400">{@selected_repository.path}</p>
                </div>
                <.button phx-click="new-worktree" variant="primary">
                  <.icon name="hero-plus" /> New Worktree
                </.button>
              </div>
            </div>
            
    <!-- Worktrees List -->
            <div class="flex-1 overflow-y-auto p-6">
              <%= if @show_new_worktree_form do %>
                <div class="mb-6 bg-white dark:bg-gray-800 rounded-lg shadow p-4">
                  <h3 class="text-lg font-medium mb-4 text-gray-900 dark:text-gray-100">
                    Create New Worktree
                  </h3>
                  <.form
                    for={@new_worktree_form}
                    phx-submit="create-worktree"
                    phx-change="validate-worktree"
                  >
                    <div class="space-y-4">
                      <.input field={@new_worktree_form[:branch]} type="text" label="Branch Name" />
                      <div class="flex gap-2">
                        <.button type="submit" variant="primary">Create</.button>
                        <.button type="button" phx-click="cancel-new-worktree">Cancel</.button>
                      </div>
                    </div>
                  </.form>
                </div>
              <% end %>

              <div class="space-y-4">
                <%= for worktree <- @worktrees do %>
                  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
                    <div class="flex items-center justify-between">
                      <div class="flex-1">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">
                          <.icon name="hero-folder" class="inline mr-2" />
                          {worktree.branch}
                        </h3>
                        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                          {worktree.path || "Creating..."}
                        </p>
                        
    <!-- Sessions for this worktree -->
                        <div class="mt-3">
                          <%= if worktree.sessions == [] do %>
                            <p class="text-sm text-gray-400 dark:text-gray-500">No active sessions</p>
                          <% else %>
                            <div class="space-y-2">
                              <%= for session <- worktree.sessions do %>
                                <div class="flex items-center text-sm">
                                  <span class={[
                                    "inline-block w-2 h-2 rounded-full mr-2",
                                    session.status == :active && "bg-green-500",
                                    session.status == :inactive && "bg-gray-400"
                                  ]}>
                                  </span>
                                  Session {String.slice(to_string(session.id), 0..7)}
                                </div>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      </div>

                      <div class="flex items-center gap-2">
                        <%= if worktree.path do %>
                          <.link
                            navigate={~p"/terminal/#{worktree.id}"}
                            class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                          >
                            <.icon name="hero-command-line" /> Terminal
                          </.link>
                          <.button phx-click="open-in-iterm" phx-value-path={worktree.path}>
                            <.icon name="hero-command-line" /> iTerm2
                          </.button>
                          <.button phx-click="open-in-zed" phx-value-path={worktree.path}>
                            <.icon name="hero-code-bracket" /> Zed
                          </.button>
                        <% end %>
                        <.button
                          phx-click="delete-worktree"
                          phx-value-id={worktree.id}
                          data-confirm="Are you sure? This will delete the git worktree."
                        >
                          <.icon name="hero-trash" />
                        </.button>
                      </div>
                    </div>
                  </div>
                <% end %>

                <%= if @worktrees == [] do %>
                  <div class="text-center py-8 text-gray-500 dark:text-gray-400">
                    <p>No worktrees yet. Create one to get started!</p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% else %>
          <div class="h-full flex items-center justify-center text-gray-500 dark:text-gray-400">
            <div class="text-center">
              <.icon
                name="hero-folder"
                class="w-16 h-16 mx-auto mb-4 text-gray-300 dark:text-gray-600"
              />
              <p class="text-lg">Select a repository to create worktrees</p>
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

  def handle_event("open-in-iterm", %{"path" => path}, socket) do
    # Generate the iTerm2 URL scheme
    # This URL will open iTerm2, cd to the path, and run claude code
    encoded_path = URI.encode(path)
    command = URI.encode("cd #{path} && claude code")
    iterm_url = "iterm2://app/command?d=#{encoded_path}&c=#{command}"

    {:noreply,
     socket
     |> push_event("open-url", %{url: iterm_url})
     |> put_flash(:info, "Opening in iTerm2...")}
  end

  def handle_event("open-in-zed", %{"path" => path}, socket) do
    # Use Zed's command line interface to open the directory
    # This will open Zed with the worktree directory
    case System.cmd("zed", [path], stderr_to_stdout: true) do
      {_output, 0} ->
        {:noreply, put_flash(socket, :info, "Opening in Zed...")}

      {_output, _status} ->
        # Fallback to using the zed:// URL scheme if available
        zed_url = "zed://file/#{URI.encode(path)}"

        {:noreply,
         socket
         |> push_event("open-url", %{url: zed_url})
         |> put_flash(:info, "Opening in Zed...")}
    end
  end

  def handle_event("remove-repository", %{"id" => repo_id}, socket) do
    case Ash.destroy(Ash.get!(ClaudeLive.Claude.Repository, repo_id)) do
      :ok ->
        repositories = Ash.read!(ClaudeLive.Claude.Repository)

        # If the removed repository was selected, clear the selection
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
  end

  defp generate_branch_name do
    # Pick a random city and make it lowercase
    Enum.random(@us_cities) |> String.downcase()
  end
end
