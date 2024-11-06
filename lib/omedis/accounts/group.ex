defmodule Omedis.Accounts.Group do
  @moduledoc """
  This is the log category module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts,
    authorizers: [Ash.Policy.Authorizer]

  alias Omedis.Accounts.GroupUser
  alias Omedis.Accounts.User

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

  identities do
    identity :unique_slug_per_tenant, [:slug, :tenant_id]
  end

  code_interface do
    domain Omedis.Accounts
    define :create
    define :update
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_tenant_id
    define :by_slug, get_by: [:slug], action: :read
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

    read :by_slug do
      argument :slug, :string do
        allow_nil? false
      end

      filter expr(slug == ^arg(:slug))
    end

    read :by_tenant_id do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(sort: :created_at)

      filter expr(tenant_id == ^arg(:tenant_id))
    end

    destroy :destroy do
    end
  end

  validations do
    validate present(:name)
  end

  def slug_exists?(slug, tenant_id) do
    __MODULE__
    |> Ash.Query.filter(slug: slug, tenant_id: tenant_id)
    |> Ash.read_one!(authorize?: false)
    |> case do
      nil -> false
      _ -> true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :ci_string, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end

    belongs_to :user, User do
      allow_nil? true
      attribute_writable? true
    end

    many_to_many :members, User do
      through GroupUser
    end

    has_many :group_memberships, GroupUser

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.Group.Relationships.GroupAccessRights
    end
  end

  policies do
    policy action_type([:create, :update, :destroy]) do
      authorize_if Omedis.Accounts.CanAccessResource
    end

    policy action_type([:read]) do
      authorize_if Omedis.Accounts.AccessFilter
    end
  end
end
