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
    defaults [:read]

    create :create do
      accept [:email, :language, :creator_id, :organisation_id]

      primary? true
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
  end

  policies do
    policy do
      authorize_if always()
    end
  end
end
