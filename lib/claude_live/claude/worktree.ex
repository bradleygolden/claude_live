defmodule ClaudeLive.Claude.Worktree do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :branch, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :project, ClaudeLive.Claude.Project do
      allow_nil? false
      attribute_type :uuid
    end

    has_many :sessions, ClaudeLive.Claude.Session
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  sqlite do
    table "worktrees"
    repo ClaudeLive.Repo
  end
end
