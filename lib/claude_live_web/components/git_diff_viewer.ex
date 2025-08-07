defmodule ClaudeLiveWeb.Components.GitDiffViewer do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :diff_files, :list, default: []
  attr :expanded_files, :any, default: MapSet.new()
  attr :file_diffs, :map, default: %{}
  attr :on_toggle_file, :string, default: "toggle-file-diff"
  attr :class, :string, default: ""

  def git_diff_viewer(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <%= if length(@diff_files) > 0 do %>
        <div class="space-y-1">
          <%= for file <- @diff_files do %>
            <% file_key = "#{@id}:#{file.path}" %>
            <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <button
                phx-click={@on_toggle_file}
                phx-value-viewer-id={@id}
                phx-value-file-path={file.path}
                class="w-full flex items-center justify-between px-3 py-2 text-xs bg-gray-50 dark:bg-gray-800/50 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              >
                <div class="flex items-center">
                  <span class={[
                    "font-bold mr-2",
                    file.status == :untracked && "text-gray-400",
                    file.status == :modified && "text-yellow-400",
                    file.status == :staged_modified && "text-green-400",
                    file.status == :deleted && "text-red-400",
                    file.status == :added && "text-green-400"
                  ]}>
                    {status_icon(file.status)}
                  </span>
                  <span class="text-gray-600 dark:text-gray-300 truncate">
                    {file.path}
                  </span>
                </div>
                <svg
                  class={[
                    "w-3 h-3 text-gray-400 transition-transform duration-200",
                    MapSet.member?(@expanded_files, file_key) && "rotate-180"
                  ]}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <%= if MapSet.member?(@expanded_files, file_key) do %>
                <div class="bg-gray-950 p-3 border-t border-gray-700 max-h-96 overflow-y-auto">
                  <% diff_content = Map.get(@file_diffs, file_key, "") %>
                  <%= if diff_content != "" do %>
                    <pre class="text-xs font-mono whitespace-pre overflow-x-auto"><%= 
                      for line <- String.split(diff_content, "\n") do
                        format_diff_line(line)
                      end
                    %></pre>
                  <% else %>
                    <p class="text-xs text-gray-500">Loading diff...</p>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-4 text-sm text-gray-500 dark:text-gray-400">
          No changes detected
        </div>
      <% end %>
    </div>
    """
  end

  defp status_icon(status) do
    case status do
      :untracked -> "U"
      :modified -> "M"
      :staged_modified -> "M"
      :modified_staged_and_unstaged -> "M"
      :deleted -> "D"
      :staged_deleted -> "D"
      :added -> "A"
      :staged_added -> "A"
      _ -> "?"
    end
  end

  defp format_diff_line(line) do
    cond do
      String.starts_with?(line, "+++") || String.starts_with?(line, "---") ->
        Phoenix.HTML.raw("<span class=\"text-gray-500\">#{escape_html(line)}</span>\n")

      String.starts_with?(line, "@@") ->
        Phoenix.HTML.raw("<span class=\"text-cyan-500 font-bold\">#{escape_html(line)}</span>\n")

      String.starts_with?(line, "+") ->
        Phoenix.HTML.raw(
          "<span class=\"text-green-400 bg-green-900/20\">#{escape_html(line)}</span>\n"
        )

      String.starts_with?(line, "-") ->
        Phoenix.HTML.raw(
          "<span class=\"text-red-400 bg-red-900/20\">#{escape_html(line)}</span>\n"
        )

      true ->
        Phoenix.HTML.raw("<span class=\"text-gray-300\">#{escape_html(line)}</span>\n")
    end
  end

  defp escape_html(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
