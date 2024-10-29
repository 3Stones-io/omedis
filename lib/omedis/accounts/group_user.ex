defmodule Omedis.Accounts.GroupUser do
  @moduledoc """
  Represents a user in a group.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  alias Omedis.Accounts.CanAccessResource
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.GroupUserAccessFilter
  alias Omedis.Accounts.User

  postgres do
    table "group_users"
    repo Omedis.Repo
  end

  identities do
    identity :unique_group_user, [:group_id, :user_id]
  end

  relationships do
    belongs_to :group, Group, primary_key?: true, allow_nil?: false
    belongs_to :user, User, primary_key?: true, allow_nil?: false

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.GroupUser.Relationships.GroupUserAccessRights
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:group_id, :user_id]

      primary? true
    end
  end

  code_interface do
    define :create
    define :read
    define :destroy
  end

  policies do
    policy action_type(:read) do
      authorize_if GroupUserAccessFilter
    end

    policy action_type([:create, :destroy]) do
      authorize_if CanAccessResource
    end
  end

  attributes do
    uuid_primary_key :id
  end
end
