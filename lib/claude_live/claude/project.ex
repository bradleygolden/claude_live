defmodule ClaudeLive.Claude.Project do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :path, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :worktrees, ClaudeLive.Claude.Worktree
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  sqlite do
    table "projects"
    repo ClaudeLive.Repo
  end
end
