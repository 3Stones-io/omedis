defmodule Omedis.Accounts.LogCategory do
  @moduledoc """
  This is the log category module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

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
      reference :tenant, on_delete: :delete
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
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_tenant_id
    define :max_position_by_tenant_id
  end

  identities do
    identity :unique_color_code_position, [:color_code, :tenant_id]
    identity :unique_position, [:position, :tenant_id]
  end

  actions do
    create :create do
      accept [
        :name,
        :tenant_id,
        :color_code,
        :position
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :tenant_id,
        :color_code,
        :position
      ]

      primary? true
      require_atomic? false
    end

    read :read do
      primary? true
    end

    read :by_tenant_id do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:log_entries])

      filter expr(tenant_id == ^arg(:tenant_id))
    end

    read :max_position_by_tenant_id do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      aggregates do
        max(:max_position, :position)
      end

      filter expr(tenant_id == ^arg(:tenant_id))
    end

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)
    validate present(:tenant_id)

    validate match(:color_code, ~r/^#[0-9A-Fa-f]{6}$/),
      message: "Color code must be a valid hex color code eg. #FF0000"

    validate present(:color_code)

    validate present(:position)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :tenant_id, :uuid, allow_nil?: false, public?: true

    attribute :color_code, :string, allow_nil?: true, public?: true

    attribute :position, :string, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  def get_max_position_by_tenant_id(tenant_id) do
    __MODULE__
    |> Ash.Query.filter(tenant_id: tenant_id)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.Query.select([:position])
    |> Ash.read!()
    |> Enum.at(0)
    |> case do
      nil -> 0
      record -> record.position |> String.to_integer()
    end
  end

  def get_color_code_for_a_tenant(tenant_id) do
    __MODULE__
    |> Ash.Query.filter(tenant_id: tenant_id)
    |> Ash.Query.select([:color_code])
    |> Ash.read!()
    |> Enum.map(& &1.color_code)
  end

  def select_unused_color_code(tenant_id) do
    existing_color_codes = get_color_code_for_a_tenant(tenant_id)

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
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end

    has_many :log_entries, Omedis.Accounts.LogEntry do
      domain Omedis.Accounts
    end
  end
end
