defmodule Omedis.Accounts.LogCategory do
  @moduledoc """
  This is the log category module
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

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

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)
    validate present(:tenant_id)
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

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end
  end
end
