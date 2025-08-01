defmodule ClaudeLive.Claude do
  use Ash.Domain,
    otp_app: :claude_live

  resources do
    resource ClaudeLive.Claude.Repository
    resource ClaudeLive.Claude.Worktree
    resource ClaudeLive.Claude.Session
  end
end
