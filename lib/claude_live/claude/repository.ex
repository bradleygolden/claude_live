defmodule ClaudeLive.Claude.Repository do
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

    # GitHub metadata fields
    attribute :source_type, :atom do
      constraints one_of: [:local, :cloned, :forked]
      default :local
      public? true
    end

    attribute :remote_url, :string do
      public? true
    end

    attribute :upstream_url, :string do
      public? true
    end

    attribute :github_owner, :string do
      public? true
    end

    attribute :github_name, :string do
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
    table "repositories"
    repo ClaudeLive.Repo
  end
end
