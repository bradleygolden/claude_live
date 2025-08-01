defmodule ClaudeLive.Repo.Migrations.RemoveProjectIdFromWorktrees do
  use Ecto.Migration

  def change do
    alter table(:worktrees) do
      remove :project_id
    end
  end
end
