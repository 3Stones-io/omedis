defmodule Omedis.Accounts.Organisation do
  @moduledoc """
  This is the Organisation module
  """
  alias Omedis.Accounts.CanCreateOrganisation
  alias Omedis.Accounts.CanUpdateOrganisation
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.OrganisationsAccessFilter
  alias Omedis.Accounts.Project
  alias Omedis.Validations

  require Ash.Query

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.OrganisationsAccessFilter

  @derive {Phoenix.Param, key: :slug}

  defimpl Ash.ToTenant do
    def to_tenant(%{id: id}, _resource), do: id
  end

  postgres do
    table "organisations"
    repo Omedis.Repo

    references do
      reference :owner, on_delete: :delete
    end
  end

  resource do
    plural_name :organisations
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :by_id, get_by: [:id], action: :read
    define :destroy
    define :by_owner_id
    define :by_slug, get_by: [:slug], action: :read
    define :list_paginated
  end

  actions do
    create :create do
      accept [
        :name,
        :street,
        :zip_code,
        :city,
        :country,
        :owner_id,
        :additional_info,
        :street2,
        :po_box,
        :canton,
        :phone,
        :fax,
        :email,
        :website,
        :zsr_number,
        :ean_gln,
        :uid_bfs_number,
        :trade_register_no,
        :bur_number,
        :account_number,
        :slug,
        :default_daily_start_at,
        :default_daily_end_at,
        :timezone
      ]

      primary? true
    end

    update :update do
      accept [
        :name,
        :street,
        :zip_code,
        :city,
        :country,
        :owner_id,
        :additional_info,
        :street2,
        :po_box,
        :canton,
        :phone,
        :fax,
        :email,
        :website,
        :zsr_number,
        :ean_gln,
        :uid_bfs_number,
        :trade_register_no,
        :bur_number,
        :account_number,
        :slug,
        :default_daily_start_at,
        :default_daily_end_at,
        :timezone
      ]

      primary? true
      require_atomic? false
    end

    read :read do
      primary? true
    end

    read :by_slug do
      argument :slug, :string do
        allow_nil? false
      end

      filter expr(slug == ^arg(:slug))
    end

    read :list_paginated do
      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(sort: :created_at)
    end

    destroy :destroy do
    end

    read :by_owner_id do
      argument :owner_id, :uuid do
        allow_nil? false
      end

      filter expr(owner_id == ^arg(:owner_id))
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if OrganisationsAccessFilter
    end

    policy action_type(:create) do
      authorize_if CanCreateOrganisation
    end

    policy action_type([:destroy, :update]) do
      authorize_if CanUpdateOrganisation
    end
  end

  preparations do
    prepare build(
              load: [
                :owner
              ]
            )
  end

  validations do
    validate {Validations.Timezone, attribute: :timezone}
  end

  def slug_exists?(slug) do
    __MODULE__
    |> Ash.Query.filter(slug: slug)
    |> Ash.read_one!(authorize?: false)
    |> case do
      nil -> false
      _ -> true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true

    attribute :additional_info, :string, allow_nil?: true, public?: true
    attribute :street, :string, allow_nil?: false, public?: true
    attribute :street2, :string, allow_nil?: true, public?: true

    attribute :po_box, :string, allow_nil?: true, public?: true

    attribute :zip_code, :string, allow_nil?: false, public?: true

    attribute :city, :string, allow_nil?: false, public?: true

    attribute :canton, :string, allow_nil?: true, public?: true

    attribute :country, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: true, public?: true

    attribute :owner_id, :uuid, allow_nil?: true, public?: true

    attribute :phone, :string, allow_nil?: true, public?: true

    attribute :fax, :string, allow_nil?: true, public?: true

    attribute :email, :string, allow_nil?: true, public?: true

    attribute :website, :string, allow_nil?: true, public?: true

    attribute :zsr_number, :string, allow_nil?: true, public?: true

    attribute :ean_gln, :string, allow_nil?: true, public?: true

    attribute :uid_bfs_number, :string, allow_nil?: true, public?: true

    attribute :trade_register_no, :string, allow_nil?: true, public?: true

    attribute :bur_number, :string, allow_nil?: true, public?: true

    attribute :account_number, :string, allow_nil?: true, public?: true

    attribute :iban, :string, allow_nil?: true, public?: true

    attribute :bic, :string, allow_nil?: true, public?: true

    attribute :bank, :string, allow_nil?: true, public?: true

    attribute :account_holder, :string, allow_nil?: true, public?: true

    attribute :timezone, :string,
      allow_nil?: false,
      public?: true,
      default: "GMT+0200 (Europe/Berlin)"

    attribute :slug, :ci_string do
      constraints max_length: 80
      allow_nil? false
    end

    attribute :default_daily_start_at, :time,
      allow_nil?: true,
      public?: true,
      default: ~T[08:00:00]

    attribute :default_daily_end_at, :time,
      allow_nil?: true,
      public?: true,
      default: ~T[18:00:00]

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :access_rights, Omedis.Accounts.AccessRight

    belongs_to :owner, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end

    has_many :groups, Group
    has_many :projects, Project
  end

  identities do
    identity :unique_slug, [:slug]
  end
end
