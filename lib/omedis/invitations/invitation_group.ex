defmodule Omedis.Invitations.InvitationGroup do
  @moduledoc """
  Represents a group in an invitation.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "invitation_groups"
    repo Omedis.Repo

    references do
      reference :invitation, on_delete: :delete
      reference :group, on_delete: :delete
      reference :organisation, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:invitation_id, :group_id]

      primary? true
    end
  end

  policies do
    policy do
      authorize_if always()
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :invitation, Omedis.Invitations.Invitation do
      allow_nil? false
      primary_key? true
    end

    belongs_to :group, Omedis.Accounts.Group do
      allow_nil? false
      primary_key? true
    end

    belongs_to :organisation, Omedis.Accounts.Organisation
  end
end
