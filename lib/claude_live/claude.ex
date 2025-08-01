defmodule ClaudeLive.Claude do
  use Ash.Domain,
    otp_app: :claude_live

  resources do
    resource ClaudeLive.Claude.Project
    resource ClaudeLive.Claude.Worktree
    resource ClaudeLive.Claude.Session
  end
end
