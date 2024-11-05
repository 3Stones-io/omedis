defmodule Omedis.Accounts.Project do
  @moduledoc """
  This is the project module
  """

  require Ash.Query

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  alias Omedis.Accounts.AccessFilter
  alias Omedis.Accounts.CanAccessResource

  postgres do
    table "projects"
    repo Omedis.Repo

    references do
      reference :organisation, on_delete: :delete
    end
  end

  resource do
    plural_name :projects
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :by_id, get_by: [:id], action: :read
    define :by_tenant_id
    define :list_paginated
  end

  identities do
    identity :unique_name, [:name, :organisation_id]
    identity :unique_position, [:position, :organisation_id]
  end

  actions do
    create :create do
      accept [
        :name,
        :organisation_id,
        :position
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :organisation_id,
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

      prepare build(load: [:organisation])
      filter expr(organisation_id == ^arg(:tenant_id))
    end

    read :list_paginated do
      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(sort: :created_at)
    end
  end

  validations do
    validate present(:name)
    validate present(:organisation_id)

    validate present(:position)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :organisation_id, :uuid, allow_nil?: false, public?: true

    attribute :position, :string, allow_nil?: false, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  def get_max_position_by_tenant_id(tenant_id, opts \\ []) do
    __MODULE__
    |> Ash.Query.filter(organisation_id: tenant_id)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.Query.select([:position])
    |> Ash.read!(opts)
    |> Enum.at(0)
    |> case do
      nil -> 0
      record -> record.position |> String.to_integer()
    end
  end

  relationships do
    belongs_to :organisation, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.Project.Relationships.ProjectAccessRights
    end
  end

  policies do
    policy action_type([:create, :update]) do
      authorize_if CanAccessResource
    end

    policy action_type(:read) do
      authorize_if AccessFilter
    end

    policy do
      authorize_if always()
    end
  end
end
