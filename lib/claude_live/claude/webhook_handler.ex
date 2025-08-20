defmodule ClaudeLive.Claude.WebhookHandler do
  @moduledoc """
  Handles webhook events from Claude Code hooks system.
  Processes various hook events and triggers appropriate actions in Claude Live.
  """

  require Logger
  alias Phoenix.PubSub

  @pubsub ClaudeLive.PubSub

  @doc """
  Handles incoming webhook events from Claude Code.
  """
  def handle_event(params) do
    event_type = params["hook_event_name"] || params["event"]

    Logger.info("Processing Claude webhook event: #{event_type}")

    case event_type do
      "Stop" ->
        handle_stop_event(params)

      "SubagentStop" ->
        handle_subagent_stop_event(params)

      "PostToolUse" ->
        handle_post_tool_use_event(params)

      "PreToolUse" ->
        handle_pre_tool_use_event(params)

      "Notification" ->
        handle_notification_event(params)

      "SessionStart" ->
        handle_session_start_event(params)

      "UserPromptSubmit" ->
        handle_user_prompt_submit_event(params)

      _ ->
        Logger.warning("Unknown webhook event type: #{event_type}")
        {:ok, %{status: "ignored", reason: "unknown_event_type"}}
    end
  end

  defp handle_stop_event(params) do
    # Broadcast that Claude has finished responding
    session_id = get_session_id(params)

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :stop, params}
    )

    Logger.info("Claude main agent stopped for session: #{session_id}")

    {:ok, %{status: "processed", event: "stop"}}
  end

  defp handle_subagent_stop_event(params) do
    # Broadcast that a sub-agent has finished
    session_id = get_session_id(params)
    subagent_name = params["subagent_name"]

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :subagent_stop, params}
    )

    Logger.info("Claude sub-agent '#{subagent_name}' stopped for session: #{session_id}")

    {:ok, %{status: "processed", event: "subagent_stop"}}
  end

  defp handle_post_tool_use_event(params) do
    # Handle tool usage events (Edit, Write, Bash, etc.)
    session_id = get_session_id(params)
    tool_name = params["tool_name"]

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :tool_used, params}
    )

    # Special handling for certain tools
    case tool_name do
      "Write" ->
        handle_file_write(params)

      "Edit" ->
        handle_file_edit(params)

      "Bash" ->
        handle_bash_command(params)

      _ ->
        :ok
    end

    Logger.info("Tool '#{tool_name}' used in session: #{session_id}")

    {:ok, %{status: "processed", event: "post_tool_use", tool: tool_name}}
  end

  defp handle_pre_tool_use_event(params) do
    # Pre-tool validation - we just log and broadcast for now
    session_id = get_session_id(params)
    tool_name = params["tool_name"]

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :before_tool_use, params}
    )

    Logger.info("About to use tool '#{tool_name}' in session: #{session_id}")

    {:ok, %{status: "processed", event: "pre_tool_use", tool: tool_name}}
  end

  defp handle_notification_event(params) do
    # Handle notification events (idle, permission needed, etc.)
    session_id = get_session_id(params)
    notification_type = params["notification_type"]

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :notification, params}
    )

    Logger.info("Notification '#{notification_type}' for session: #{session_id}")

    # Could trigger alerts, emails, or UI notifications here

    {:ok, %{status: "processed", event: "notification"}}
  end

  defp handle_session_start_event(params) do
    # Handle session start/resume
    session_id = get_session_id(params)

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :session_start, params}
    )

    Logger.info("Claude session started: #{session_id}")

    {:ok, %{status: "processed", event: "session_start"}}
  end

  defp handle_user_prompt_submit_event(params) do
    # Handle user prompt submission
    session_id = get_session_id(params)

    PubSub.broadcast(
      @pubsub,
      "claude:#{session_id}",
      {:claude_event, :user_prompt, params}
    )

    Logger.info("User prompt submitted in session: #{session_id}")

    {:ok, %{status: "processed", event: "user_prompt_submit"}}
  end

  defp handle_file_write(params) do
    file_path = get_in(params, ["tool_input", "file_path"])

    if file_path do
      PubSub.broadcast(
        @pubsub,
        "claude:files",
        {:file_event, :created, file_path}
      )
    end

    :ok
  end

  defp handle_file_edit(params) do
    file_path = get_in(params, ["tool_input", "file_path"])

    if file_path do
      PubSub.broadcast(
        @pubsub,
        "claude:files",
        {:file_event, :modified, file_path}
      )
    end

    :ok
  end

  defp handle_bash_command(params) do
    command = get_in(params, ["tool_input", "command"])

    if command && String.contains?(command, "git") do
      PubSub.broadcast(
        @pubsub,
        "claude:git",
        {:git_command, command}
      )
    end

    :ok
  end

  defp get_session_id(params) do
    # Try to extract session ID from various possible locations
    params["session_id"] ||
      params["claude_session_id"] ||
      get_in(params, ["context", "session_id"]) ||
      "unknown"
  end
end
