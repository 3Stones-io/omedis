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
    domain Omedis.Accounts
    define :by_id, get_by: [:id], action: :read
    define :create
    define :destroy
    define :list_paginated
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false

    attribute :expires_at, :utc_datetime,
      allow_nil?: false,
      default: fn -> DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * 7, :second) end

    attribute :language, :string, allow_nil?: false

    attribute :inserted_at, :utc_datetime_usec do
      writable? true
      default &DateTime.utc_now/0
      match_other_defaults? true
      allow_nil? false
    end

    attribute :updated_at, :utc_datetime_usec do
      writable? false
      default &DateTime.utc_now/0
      update_default &DateTime.utc_now/0
      match_other_defaults? true
      allow_nil? false
    end
  end

  actions do
    defaults [:destroy, :read]

    read :list_paginated do
      argument :sort_order, :atom do
        allow_nil? true
        default :asc
        constraints one_of: [:asc, :desc]
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(sort: [inserted_at: arg(:sort_order)])
    end

    update :update do
      accept [:email, :language, :creator_id, :organisation_id, :inserted_at]

      primary? true
    end

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

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.Invitation.Relationships.InvitationAccessRights
    end

    many_to_many :groups, Omedis.Accounts.Group do
      through Omedis.Accounts.InvitationGroup
    end
  end

  policies do
    policy action_type([:create, :destroy]) do
      authorize_if Omedis.Accounts.CanAccessResource
    end

    policy action_type(:read) do
      authorize_if Omedis.Accounts.AccessFilter
    end
  end
end
