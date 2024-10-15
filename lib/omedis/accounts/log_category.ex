defmodule Omedis.Accounts.LogCategory do
  @moduledoc """
  This is the log category module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts,
    notifiers: [Omedis.Accounts.Notifiers]

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
    table "log_categories"
    repo Omedis.Repo

    references do
      reference :group, on_delete: :delete
      reference :project, on_delete: :delete
    end
  end

  resource do
    plural_name :log_categories
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :increment_position, action: :increment_position
    define :decrement_position, action: :decrement_position
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_group_id
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
        :project_id,
        :name,
        :position,
        :slug
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :group_id,
        :project_id,
        :color_code,
        :position,
        :slug
      ]

      primary? true
      require_atomic? false
    end

    update :increment_position do
      change {Omedis.Accounts.Changes.UpdateLogCategoryPositions, direction: :inc}
      require_atomic? false
    end

    update :decrement_position do
      change {Omedis.Accounts.Changes.UpdateLogCategoryPositions, direction: :dec}
      require_atomic? false
    end

    read :read do
      primary? true
    end

    read :by_group_id do
      argument :group_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:log_entries], sort: [position: :asc])

      filter expr(group_id == ^arg(:group_id))
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

    validate present(:position)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :group_id, :uuid, allow_nil?: false, public?: true
    attribute :project_id, :uuid, allow_nil?: false, public?: true

    attribute :color_code, :string, allow_nil?: true, public?: true

    attribute :position, :integer, allow_nil?: true, public?: true

    attribute :slug, :string do
      constraints max_length: 80
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
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
