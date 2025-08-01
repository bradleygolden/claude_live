defmodule ClaudeLive.Claude.Session do
  use Ash.Resource,
    otp_app: :claude_live,
    domain: ClaudeLive.Claude,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:pending, :running, :completed, :error]
      default :pending
    end

    attribute :cwd, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :worktree, ClaudeLive.Claude.Worktree do
      allow_nil? false
      attribute_type :uuid
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  sqlite do
    table "sessions"
    repo ClaudeLive.Repo
  end
end
