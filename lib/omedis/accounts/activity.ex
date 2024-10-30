defmodule Omedis.Accounts.Activity do
  @moduledoc """
  This is the activity module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts,
    notifiers: [Omedis.Accounts.Notifiers],
    authorizers: [Ash.Policy.Authorizer]

  @github_issue_color_codes [
    "#1f77b4",
    "#ff7f0e",
    "#2ca02c",
    "#d62728",
    "#9467bd",
    "#8c564b",
    "#e377c2",
    "#7f7f7f",
    "#bcbd22",
    "#17becf"
  ]
  postgres do
    table "activities"
    repo Omedis.Repo

    references do
      reference :group, on_delete: :delete
      reference :project, on_delete: :delete
    end
  end

  resource do
    plural_name :activities
  end

  policies do
    policy action(:create) do
      authorize_if Omedis.Accounts.Checks.GroupAndProjectExist
    end

    policy do
      authorize_if always()
    end
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :update_position
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_group_id
    define :list_paginated
    define :by_group_id_and_project_id
    define :max_position_by_group_id
  end

  identities do
    identity :unique_color_code_position, [:color_code, :group_id]

    identity :unique_position, [:position, :group_id]
    identity :unique_slug, [:slug, :group_id], eager_check?: true
  end

  actions do
    create :create do
      accept [
        :color_code,
        :group_id,
        :is_default,
        :project_id,
        :name,
        :slug
      ]

      change Omedis.Accounts.Changes.NewLogCategoryPosition
      change Omedis.Accounts.Changes.SetDefaultLogCategory

      primary? true
    end

    update :update do
      accept [
        :is_default,
        :name,
        :group_id,
        :project_id,
        :color_code,
        :position,
        :slug
      ]

      change Omedis.Accounts.Changes.SetDefaultLogCategory

      primary? true
      require_atomic? false
    end

    update :update_position do
      accept [:position]

      change Omedis.Accounts.Changes.UpdateLogCategoryPositions

      require_atomic? false
    end

    update :decrement_position do
      accept []

      change atomic_update(:position, expr(position - 1))
    end

    update :increment_position do
      accept []

      change atomic_update(:position, expr(position + 1))
    end

    read :read do
      primary? true

      pagination offset?: true, keyset?: true, required?: false
    end

    read :by_group_id do
      argument :group_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(load: [:log_entries], sort: [position: :asc])

      filter expr(group_id == ^arg(:group_id))
    end

    read :list_paginated do
      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(sort: [position: :asc])
    end

    read :by_group_id_and_project_id do
      argument :group_id, :uuid do
        allow_nil? false
      end

      argument :project_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:log_entries])

      filter expr(group_id == ^arg(:group_id) and project_id == ^arg(:project_id))
    end

    read :max_position_by_group_id do
      argument :group_id, :uuid do
        allow_nil? false
      end

      aggregates do
        max(:max_position, :position)
      end

      filter expr(group_id == ^arg(:group_id))
    end

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)

    validate match(:color_code, ~r/^#[0-9A-Fa-f]{6}$/),
      message: "Color code must be a valid hex color code eg. #FF0000"

    validate present(:color_code)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :group_id, :uuid, allow_nil?: false, public?: true
    attribute :project_id, :uuid, allow_nil?: false, public?: true

    attribute :color_code, :string, allow_nil?: true, public?: true
    attribute :is_default, :boolean, allow_nil?: false, default: false, public?: true
    attribute :position, :integer, allow_nil?: true, public?: true

    attribute :slug, :string do
      constraints max_length: 80
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  def move_up(log_category) do
    case log_category.position do
      1 ->
        {:ok, log_category}

      _ ->
        __MODULE__.update_position(log_category, %{position: log_category.position - 1})
    end
  end

  def move_down(log_category) do
    last_position = get_max_position_by_group_id(log_category.group_id)

    case log_category.position do
      ^last_position ->
        {:ok, log_category}

      _ ->
        __MODULE__.update_position(log_category, %{position: log_category.position + 1})
    end
  end

  def slug_exists?(slug) do
    __MODULE__
    |> Ash.Query.filter(slug: slug)
    |> Ash.read_one!()
  end

  def get_max_position_by_group_id(group_id) do
    __MODULE__
    |> Ash.Query.filter(group_id: group_id)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.Query.select([:position])
    |> Ash.read!()
    |> Enum.at(0)
    |> case do
      nil -> 0
      record -> record.position
    end
  end

  def get_color_code_for_a_group(group_id) do
    __MODULE__
    |> Ash.Query.filter(group_id: group_id)
    |> Ash.Query.select([:color_code])
    |> Ash.read!()
    |> Enum.map(& &1.color_code)
  end

  def select_unused_color_code(group_id) do
    existing_color_codes = get_color_code_for_a_group(group_id)

    unused_color_code =
      @github_issue_color_codes
      |> Enum.filter(fn color_code -> color_code not in existing_color_codes end)
      |> Enum.random()

    case unused_color_code do
      nil -> Enum.random(@github_issue_color_codes)
      color_code -> color_code
    end
  end

  def get_default_log_category(group_id) do
    __MODULE__
    |> Ash.Query.filter(group_id: group_id, is_default: true)
    |> Ash.read_one!()
  end

  relationships do
    belongs_to :group, Omedis.Accounts.Group do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :project, Omedis.Accounts.Project do
      allow_nil? false
      attribute_writable? true
    end

    has_many :log_entries, Omedis.Accounts.LogEntry do
      domain Omedis.Accounts
    end
  end
end
