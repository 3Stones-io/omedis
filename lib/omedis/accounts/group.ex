defmodule Omedis.Accounts.Group do
  @moduledoc """
  This is the log category module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "groups"
    repo Omedis.Repo

    references do
      reference :tenant, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  resource do
    plural_name :groups
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :destroy
    define :by_tenant_id
  end

  actions do
    create :create do
      accept [
        :name,
        :tenant_id,
        :user_id,
        :slug
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :slug
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

      filter expr(tenant_id == ^arg(:tenant_id))
    end

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end

    belongs_to :user, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end
  end
end
