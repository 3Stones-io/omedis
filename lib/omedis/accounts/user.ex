defmodule Omedis.Accounts.User do
  @moduledoc """
  Represents a user in the system.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshArchival.Resource],
    domain: Omedis.Accounts

  alias Omedis.Accounts.User.Changes.AddInvitedUserToInvitationGroups
  alias Omedis.Accounts.User.Changes.AssociateUserWithInvitation
  alias Omedis.Accounts.User.Changes.MaybeAddOrganisationDefaults
  alias Omedis.Accounts.User.Changes.MaybeCreateOrganisation
  alias Omedis.Accounts.User.Checks.CanDeleteAccount
  alias Omedis.Accounts.User.Validations.Language
  alias Omedis.Groups.Group
  alias Omedis.Groups.GroupMembership

  postgres do
    table "users"
    repo Omedis.Repo
  end

  authentication do
    strategies do
      password :password do
        identity_field :email

        sign_in_tokens_enabled? true
        confirmation_required?(false)

        register_action_accept([
          :email,
          :lang,
          :current_organisation_id
        ])

        resettable do
          sender Omedis.Accounts.User.Notifiers.SendPasswordResetEmail
        end
      end
    end

    tokens do
      enabled? true
      token_resource Omedis.Accounts.Token

      signing_secret fn _, _ ->
        Application.fetch_env(:omedis, :token_signing_secret)
      end

      store_all_tokens? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :current_organisation_id,
        :email,
        :hashed_password,
        :first_name,
        :last_name,
        :gender,
        :birthdate,
        :lang,
        :daily_start_at,
        :daily_end_at
      ]

      primary? true

      change MaybeAddOrganisationDefaults
    end

    update :update do
      accept [
        :email,
        :hashed_password,
        :first_name,
        :last_name,
        :gender,
        :birthdate,
        :lang,
        :current_organisation_id
      ]

      primary? true
      require_atomic? false
    end
  end

  policies do
    policy action_type(:destroy) do
      authorize_if CanDeleteAccount
    end

    policy do
      authorize_if always()
    end
  end

  preparations do
    prepare build(
              load: [
                :full_name
              ]
            )
  end

  changes do
    change {MaybeCreateOrganisation, []} do
      where [action_is(:create)]
    end

    change {MaybeCreateOrganisation, []} do
      where [action_is(:register_with_password)]
    end

    change {AssociateUserWithInvitation, []} do
      where [action_is(:create)]
    end

    change {AssociateUserWithInvitation, []} do
      where [action_is(:register_with_password)]
    end

    change {AddInvitedUserToInvitationGroups, []} do
      where [action_is(:create)]
    end

    change {AddInvitedUserToInvitationGroups, []} do
      where [action_is(:register_with_password)]
    end
  end

  validations do
    validate {Language, attribute: :lang}
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :first_name, :string, allow_nil?: true, public?: true
    attribute :last_name, :string, allow_nil?: true, public?: true
    attribute :gender, :string, allow_nil?: true, public?: true
    attribute :birthdate, :date, allow_nil?: true, public?: true
    attribute :current_organisation_id, :uuid, allow_nil?: true, public?: false
    attribute :lang, :string, allow_nil?: false, public?: true, default: "en"
    attribute :daily_start_at, :time, allow_nil?: true, public?: true
    attribute :daily_end_at, :time, allow_nil?: true, public?: true
    attribute :archived_at, :utc_datetime_usec, allow_nil?: true, public?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    many_to_many :groups, Group do
      through GroupMembership
    end
  end

  calculations do
    calculate :full_name, :string, expr(first_name <> " " <> last_name)
  end

  identities do
    identity :unique_email, [:email]
  end

  defimpl Phoenix.HTML.Safe, for: Omedis.Accounts.User do
    def to_iodata(user) do
      user.full_name || Ash.CiString.value(user.email)
    end
  end
end
