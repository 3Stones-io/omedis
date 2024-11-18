defmodule Omedis.Accounts.Activity do
  @moduledoc """
  This is the activity module
  """

  require Ash.Query

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts,
    notifiers: [Omedis.Accounts.Notifiers],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "activities"
    repo Omedis.Repo

    references do
      reference :group, on_delete: :delete
      reference :organisation, on_delete: :delete
      reference :project, on_delete: :delete
    end
  end

  resource do
    plural_name :activities
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :update_position
    define :by_id, get_by: [:id], action: :read
    define :list_paginated
    define :by_group_id_and_project_id
  end

  actions do
    create :create do
      accept [
        :color_code,
        :group_id,
        :is_default,
        :project_id,
        :name,
        :slug
      ]

      change Omedis.Accounts.Changes.NewActivityPosition
      change Omedis.Accounts.Changes.SetDefaultActivity

      primary? true
    end

    update :update do
      accept [
        :is_default,
        :name,
        :group_id,
        :project_id,
        :color_code,
        :position,
        :slug
      ]

      change Omedis.Accounts.Changes.SetDefaultActivity

      primary? true
      require_atomic? false
    end

    update :update_position do
      accept [:position]

      change Omedis.Accounts.Changes.UpdateActivityPositions

      require_atomic? false
    end

    update :decrement_position do
      accept []

      change atomic_update(:position, expr(position - 1))
    end

    update :increment_position do
      accept []

      change atomic_update(:position, expr(position + 1))
    end

    read :read do
      primary? true

      pagination offset?: true, keyset?: true, required?: false
    end

    read :list_paginated do
      argument :group_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(load: [:events], sort: [position: :asc])

      filter expr(group_id == ^arg(:group_id))
    end

    read :by_group_id_and_project_id do
      argument :group_id, :uuid do
        allow_nil? false
      end

      argument :project_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:events])

      filter expr(group_id == ^arg(:group_id) and project_id == ^arg(:project_id))
    end
  end

  policies do
    policy action_type([:create, :update, :destroy]) do
      authorize_if Omedis.Accounts.CanAccessResource
    end

    policy action_type(:read) do
      authorize_if Omedis.Accounts.AccessFilter
    end
  end

  validations do
    validate present(:name)

    validate match(:color_code, ~r/^#[0-9A-Fa-f]{6}$/),
      message: "Color code must be a valid hex color code eg. #FF0000"

    validate present(:color_code)
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :group_id, :uuid, allow_nil?: false, public?: true
    attribute :project_id, :uuid, allow_nil?: false, public?: true

    attribute :color_code, :string, allow_nil?: true, public?: true
    attribute :is_default, :boolean, allow_nil?: false, default: false, public?: true
    attribute :position, :integer, allow_nil?: true, public?: true

    attribute :slug, :string do
      constraints max_length: 80
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :group, Omedis.Accounts.Group do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :project, Omedis.Accounts.Project do
      allow_nil? false
      attribute_writable? true
    end

    has_many :events, Omedis.Accounts.Event do
      domain Omedis.Accounts
    end

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.Activity.Relationships.ActivityAccessRights
    end

    belongs_to :organisation, Omedis.Accounts.Organisation
  end

  identities do
    identity :unique_color_code_position, [:color_code, :group_id]

    identity :unique_position, [:position, :group_id]
    identity :unique_slug, [:slug, :group_id], eager_check?: true
  end
end
