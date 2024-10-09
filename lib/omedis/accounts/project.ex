defmodule Omedis.Accounts.Project do
  @moduledoc """
  This is the project module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "projects"
    repo Omedis.Repo

    references do
      reference :tenant, on_delete: :delete
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
    define :destroy
    define :by_tenant_id
    define :list_paginated
    define :max_position_by_tenant_id
  end

  identities do
    identity :unique_name, [:name, :tenant_id]
    identity :unique_position, [:position, :tenant_id]
  end

  actions do
    create :create do
      accept [
        :name,
        :tenant_id,
        :position
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :tenant_id,
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

      prepare build(load: [:tenant])
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

    read :list_paginated do
      pagination offset?: true, default_limit: 10
      prepare build(sort: :created_at)
    end

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)
    validate present(:tenant_id)

    validate present(:position)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :tenant_id, :uuid, allow_nil?: false, public?: true

    attribute :position, :string, allow_nil?: false, public?: true

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

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end
  end
end
