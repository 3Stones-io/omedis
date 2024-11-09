defmodule Omedis.Accounts.InvitationGroup do
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
    end
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:invitation_id, :group_id]

      primary? true
    end
  end

  relationships do
    belongs_to :invitation, Omedis.Accounts.Invitation do
      allow_nil? false
      primary_key? true
    end

    belongs_to :group, Omedis.Accounts.Group do
      allow_nil? false
      primary_key? true
    end
  end

  policies do
    policy do
      authorize_if always()
    end
  end
end
