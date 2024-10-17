defmodule Omedis.Accounts.AccessRight do
  @moduledoc """
  Represents an access right for a resource.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "access_rights"
    repo Omedis.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :resource_name, :string, allow_nil?: false
    attribute :read, :boolean, default: false
    attribute :write, :boolean, default: false
    attribute :update, :boolean, default: false
    attribute :create, :boolean, default: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant
    belongs_to :group, Omedis.Accounts.Group
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [
        :resource_name,
        :read,
        :write,
        :update,
        :create,
        :tenant_id,
        :group_id
      ]

      primary? true
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
  end
end
