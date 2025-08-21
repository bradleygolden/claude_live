defmodule ClaudeLive.Claude do
  use Ash.Domain,
    otp_app: :claude_live,
    extensions: [AshAi]

  resources do
    resource ClaudeLive.Claude.Repository
    resource ClaudeLive.Claude.Worktree
    resource ClaudeLive.Claude.Session
    resource ClaudeLive.Claude.Event
  end

  tools do
    tool :create_worktree, ClaudeLive.Claude.Worktree, :create do
      description "Create a new git worktree for a feature branch"
    end

    tool :archive_worktree, ClaudeLive.Claude.Worktree, :destroy do
      description "Archive a worktree (soft delete)"
    end

    tool :restore_worktree, ClaudeLive.Claude.Worktree, :unarchive do
      description "Restore an archived worktree"
    end

    tool :list_worktrees, ClaudeLive.Claude.Worktree, :read do
      description "List all active worktrees"
    end

    tool :list_archived_worktrees, ClaudeLive.Claude.Worktree, :archived do
      description "List all archived worktrees"
    end

    tool :create_repository, ClaudeLive.Claude.Repository, :create do
      description "Clone or add a new repository"
    end

    tool :list_repositories, ClaudeLive.Claude.Repository, :read do
      description "List all repositories"
    end

    tool :sync_worktrees, ClaudeLive.Claude.Repository, :sync_worktrees do
      description "Sync worktrees with git for a repository"
    end
  end
end
