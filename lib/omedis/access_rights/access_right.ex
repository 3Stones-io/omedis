defmodule Omedis.AccessRights.AccessRight do
  @moduledoc """
  Represents an access right for a resource.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.AccessRights

  postgres do
    table "access_rights"
    repo Omedis.Repo

    references do
      reference :organisation, on_delete: :delete
      reference :group, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :resource_name,
        :read,
        :destroy,
        :update,
        :create,
        :group_id
      ]

      primary? true
    end

    update :update do
      accept [:read, :destroy, :update, :create]

      primary? true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id

    attribute :resource_name, :string, allow_nil?: false
    attribute :read, :boolean, default: false
    attribute :destroy, :boolean, default: false
    attribute :update, :boolean, default: false
    attribute :create, :boolean, default: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organisation, Omedis.Accounts.Organisation
    belongs_to :group, Omedis.Groups.Group
  end
end
