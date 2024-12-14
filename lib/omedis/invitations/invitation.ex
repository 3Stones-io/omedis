defmodule Omedis.Invitations.Invitation do
  @moduledoc """
  Represents an invitation to join an organisation.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Invitations,
    extensions: [AshStateMachine]

  postgres do
    table "invitations"
    repo Omedis.Repo

    references do
      reference :organisation, on_delete: :delete
    end
  end

  state_machine do
    initial_states([:accepted, :expired, :pending])
    default_initial_state(:pending)
    state_attribute(:status)

    transitions do
      transition(:accept, from: :pending, to: [:accepted])
      transition(:expire, from: :pending, to: [:expired])
    end
  end

  code_interface do
    domain Omedis.Invitations
    define :accept
    define :by_id, get_by: [:id]
    define :create
    define :destroy
    define :expire
    define :list_paginated
    define :update
  end

  actions do
    defaults [:read, :destroy]

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

    update :accept do
      require_atomic? false

      change transition_state(:accepted)
      change relate_actor(:user)
    end

    update :expire do
      change transition_state(:expired)
    end

    update :update do
      accept [:email, :language, :creator_id, :inserted_at]

      primary? true
    end

    create :create do
      accept [:email, :language, :creator_id, :expires_at, :status]

      argument :groups, {:array, :uuid}, allow_nil?: false

      change manage_relationship(:groups,
               on_lookup: :relate,
               on_no_match: :error,
               on_match: :ignore,
               on_missing: :unrelate
             )

      change Omedis.Invitations.Invitation.Changes.SendInvitationEmail
      change Omedis.Invitations.Invitation.Changes.EnsureExpirationIsInFuture
      change Omedis.Invitations.Invitation.Changes.ScheduleInvitationExpiration

      validate {Omedis.Invitations.Invitation.Validations.ValidateNoPendingInvitation, []}
      validate {Omedis.Invitations.Invitation.Validations.ValidateUserNotRegistered, []}

      primary? true
    end

    read :by_id
  end

  policies do
    policy action_type([:create, :destroy]) do
      authorize_if Omedis.AccessRights.AccessRight.Checks.CanAccessResource
    end

    policy action_type([:create, :update]) do
      authorize_if AshStateMachine.Checks.ValidNextState
    end

    policy action(:by_id) do
      authorize_if Omedis.Invitations.Invitation.Checks.InvitationNotExpiredFilter
    end

    policy action([:list_paginated, :read]) do
      authorize_if Omedis.AccessRights.AccessRight.Checks.AccessFilter
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? true
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

  relationships do
    belongs_to :creator, Omedis.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :organisation, Omedis.Accounts.Organisation

    belongs_to :user, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end

    has_many :access_rights, Omedis.AccessRights.AccessRight do
      manual Omedis.Invitations.Invitation.Relationships.InvitationAccessRights
    end

    many_to_many :groups, Omedis.Groups.Group do
      through Omedis.Invitations.InvitationGroup
    end
  end
end
