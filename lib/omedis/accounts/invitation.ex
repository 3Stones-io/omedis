defmodule Omedis.Accounts.Invitation do
  @moduledoc """
  Represents an invitation to join an organisation.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "invitations"
    repo Omedis.Repo
  end

  code_interface do
    define :create
    define :by_id
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false

    attribute :expires_at, :utc_datetime,
      allow_nil?: false,
      default: fn -> DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * 7, :second) end

    attribute :language, :string, allow_nil?: false

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:email, :language, :creator_id, :organisation_id, :expires_at]

      argument :groups, {:array, :uuid}, allow_nil?: false

      change manage_relationship(:groups,
               on_lookup: :relate,
               on_no_match: :error,
               on_match: :ignore,
               on_missing: :unrelate
             )

      primary? true
    end

    read :by_id do
      argument :id, :uuid do
        allow_nil? false
      end

      filter expr(id == ^arg(:id))
    end
  end

  relationships do
    belongs_to :creator, Omedis.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :organisation, Omedis.Accounts.Organisation do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :user, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end

    many_to_many :groups, Omedis.Accounts.Group do
      through Omedis.Accounts.InvitationGroup
    end

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.Project.Relationships.InvitationAccessRights
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if Omedis.Accounts.CanAccessResource
    end

    policy action(:by_id) do
      authorize_if Omedis.Accounts.HasExpiredInvitation
    end

    policy do
      authorize_if always()
    end
  end
end
