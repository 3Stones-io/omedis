defmodule Omedis.Accounts.User do
  @moduledoc """
  Represents a user in the system.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    domain: Omedis.Accounts

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :first_name, :string, allow_nil?: false, public?: true
    attribute :last_name, :string, allow_nil?: false, public?: true
    attribute :gender, :string, allow_nil?: true, public?: true
    attribute :birthdate, :date, allow_nil?: false, public?: true
    attribute :current_tenant_id, :uuid, allow_nil?: true, public?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  code_interface do
    domain Accounts
    define :read
    define :create
    define :update
    define :destroy
    define :by_id, get_by: [:id], action: :read
    define :by_email, get_by: [:email], action: :read
  end

  calculations do
    calculate :name, :string, expr(first_name <> " " <> last_name)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :email,
        :hashed_password,
        :first_name,
        :last_name,
        :gender,
        :birthdate
      ]

      primary? true
    end

    update :update do
      accept [
        :email,
        :hashed_password,
        :first_name,
        :last_name,
        :gender,
        :birthdate,
        :current_tenant_id
      ]

      primary? true
      require_atomic? false
    end
  end

  authentication do
    strategies do
      password :password do
        identity_field :email

        sign_in_tokens_enabled? true
        confirmation_required?(false)

        register_action_accept([
          :email,
          :first_name,
          :last_name,
          :gender,
          :birthdate
        ])
      end
    end

    tokens do
      enabled? true
      token_resource Omedis.Accounts.Token

      signing_secret fn _, _ ->
        Application.fetch_env(:omedis, :token_signing_secret)
      end
    end
  end

  preparations do
    prepare build(
              load: [
                :name
              ]
            )
  end

  postgres do
    table "users"
    repo Omedis.Repo
  end

  identities do
    identity :unique_email, [:email]
  end
end
