defmodule Omedis.Accounts.User do
  @moduledoc """
  Represents a user in the system.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    domain: Omedis.Accounts

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.GroupUser
  alias Omedis.Accounts.Tenant
  alias Omedis.Validations

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :first_name, :string, allow_nil?: false, public?: true
    attribute :last_name, :string, allow_nil?: false, public?: true
    attribute :gender, :string, allow_nil?: true, public?: true
    attribute :birthdate, :date, allow_nil?: false, public?: true
    attribute :current_tenant_id, :uuid, allow_nil?: true, public?: false
    attribute :lang, :string, allow_nil?: false, public?: true, default: "en"
    attribute :daily_start_at, :time, allow_nil?: true, public?: true
    attribute :daily_end_at, :time, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  validations do
    validate {Validations.Language, attribute: :lang}
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
    calculate :as_string, :string, expr(first_name <> " " <> last_name)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :current_tenant_id,
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

      change fn changeset, _context ->
        Ash.Changeset.before_action(changeset, fn changeset ->
          maybe_add_tenant_defaults_to_changeset(changeset)
        end)
      end
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
        :current_tenant_id
      ]

      primary? true
      require_atomic? false
    end
  end

  relationships do
    many_to_many :groups, Group do
      through GroupUser
    end
  end

  authentication do
    strategies do
      password :password do
        identity_field :email

        sign_in_tokens_enabled? true
        confirmation_required?(false)

        register_action_accept([
          :current_tenant_id,
          :email,
          :first_name,
          :last_name,
          :gender,
          :birthdate,
          :lang,
          :daily_start_at,
          :daily_end_at
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
                :as_string
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

  defp maybe_add_tenant_defaults_to_changeset(changeset) do
    tenant_id = Ash.Changeset.get_attribute(changeset, :current_tenant_id)

    if tenant_id do
      tenant = Tenant.by_id!(tenant_id)

      changeset_attributes =
        changeset.attributes
        |> Map.drop([:id, :created_at, :updated_at, :current_tenant_id])
        |> Map.merge(
          %{
            daily_start_at: tenant.default_daily_start_at,
            daily_end_at: tenant.default_daily_end_at
          },
          fn _key, v1, _v2 -> v1 end
        )

      Ash.Changeset.change_attributes(changeset, changeset_attributes)
    else
      changeset
    end
  end
end
