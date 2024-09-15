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
    attribute :current_tenant_id, :uuid, allow_nil?: false, public?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  authentication do
    strategies do
      password :password do
        identity_field :email
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

  postgres do
    table "users"
    repo Omedis.Repo
  end

  identities do
    identity :unique_email, [:email]
  end
end
