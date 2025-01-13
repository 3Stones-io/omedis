defmodule Omedis.Groups.Group do
  @moduledoc """
  This is the group module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Groups,
    authorizers: [Ash.Policy.Authorizer]

  alias Omedis.Accounts.User
  alias Omedis.Groups.GroupMembership

  @derive {Phoenix.Param, key: :slug}

  postgres do
    table "groups"
    repo Omedis.Repo

    references do
      reference :organisation, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  resource do
    plural_name :groups
  end

  code_interface do
    domain Omedis.Groups
    define :create
    define :update
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_organisation_id
    define :by_slug, get_by: [:slug], action: :read
    define :latest_by_organisation_id
  end

  actions do
    create :create do
      accept [
        :name,
        :user_id
      ]

      change Omedis.Groups.Group.Changes.MaybeSlugifyName
      primary? true
    end

    update :update do
      accept [
        :name
      ]

      primary? true
      require_atomic? false

      change Omedis.Groups.Group.Changes.MaybeSlugifyName

      change fn changeset, _context ->
        case changeset.context do
          %{updated_at: updated_at} ->
            Ash.Changeset.force_change_attribute(changeset, :updated_at, updated_at)

          _ ->
            changeset
        end
      end
    end

    read :read do
      primary? true
    end

    read :by_slug do
      argument :slug, :string do
        allow_nil? false
      end

      filter expr(slug == ^arg(:slug))
    end

    read :by_organisation_id do
      argument :organisation_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(sort: :created_at)

      filter expr(organisation_id == ^arg(:organisation_id))
    end

    read :latest_by_organisation_id do
      argument :organisation_id, :uuid do
        allow_nil? false
      end

      prepare build(sort: [updated_at: :desc], limit: 1)

      filter expr(organisation_id == ^arg(:organisation_id))
    end

    destroy :destroy do
    end
  end

  policies do
    policy action_type([:create, :update, :destroy]) do
      authorize_if Omedis.AccessRights.AccessRight.Checks.CanAccessResource
    end

    policy action_type([:read]) do
      authorize_if Omedis.AccessRights.AccessRight.Checks.AccessFilter
    end
  end

  validations do
    validate present(:name)
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :ci_string, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at, writable?: true
  end

  relationships do
    belongs_to :organisation, Omedis.Accounts.Organisation

    belongs_to :user, User do
      allow_nil? true
      attribute_writable? true
    end

    many_to_many :users, User do
      through GroupMembership
    end

    has_many :group_memberships, GroupMembership

    has_many :access_rights, Omedis.AccessRights.AccessRight do
      manual Omedis.Groups.Group.Relationships.GroupAccessRights
    end
  end

  identities do
    identity :unique_slug_per_organisation, :slug
  end
end
