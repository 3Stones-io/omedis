defmodule Omedis.Groups.GroupMembership do
  @moduledoc """
  Represents a user in a group.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Groups

  alias Omedis.Accounts.AccessFilter
  alias Omedis.Accounts.CanAccessResource
  alias Omedis.Accounts.User
  alias Omedis.Groups.Group

  postgres do
    table "group_memberships"
    repo Omedis.Repo

    references do
      reference :group, on_delete: :delete
      reference :organisation, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  code_interface do
    define :create
    define :read
    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:group_id, :user_id]

      primary? true
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if AccessFilter
    end

    policy action_type([:create, :destroy]) do
      authorize_if CanAccessResource
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :group, Group, primary_key?: true, allow_nil?: false
    belongs_to :user, User, primary_key?: true, allow_nil?: false

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Groups.GroupMembership.Relationships.GroupMembershipAccessRights
    end

    belongs_to :organisation, Omedis.Accounts.Organisation
  end

  identities do
    identity :unique_group_membership, [:group_id, :user_id]
  end
end
