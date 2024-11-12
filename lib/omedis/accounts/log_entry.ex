defmodule Omedis.Accounts.LogEntry do
  @moduledoc """
  This is the log entry module
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  alias Omedis.Accounts.AccessFilter
  alias Omedis.Accounts.CanAccessResource

  postgres do
    table "log_entries"
    repo Omedis.Repo

    references do
      reference :activity, on_delete: :delete
      reference :organisation, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  resource do
    plural_name :log_entries
  end

  code_interface do
    domain Omedis.Accounts
    define :read
    define :create
    define :update
    define :by_activity
    define :by_activity_today
    define :by_organisation
    define :by_organisation_today
    define :by_id, get_by: [:id], action: :read
  end

  actions do
    read :by_activity do
      argument :activity_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit)

      prepare build(sort: :created_at)

      filter expr(activity_id == ^arg(:activity_id))
    end

    read :by_organisation do
      argument :organisation_id, :uuid do
        allow_nil? false
      end

      filter expr(organisation_id == ^arg(:organisation_id))
    end

    read :by_organisation_today do
      argument :organisation_id, :uuid do
        allow_nil? false
      end

      filter expr(
               organisation_id == ^arg(:organisation_id) and
                 fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at)
             )
    end

    read :by_activity_today do
      argument :activity_id, :uuid do
        allow_nil? false
      end

      filter expr(
               activity_id == ^arg(:activity_id) and
                 fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at)
             )
    end

    create :create do
      accept [
        :created_at,
        :comment,
        :start_at,
        :end_at,
        :activity_id,
        :user_id
      ]

      primary? true
    end

    update :update do
      accept [
        :comment,
        :start_at,
        :end_at,
        :activity_id,
        :user_id
      ]

      primary? true
      require_atomic? false
    end

    read :read do
      primary? true
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if AccessFilter
    end

    policy action_type([:create, :update]) do
      authorize_if CanAccessResource
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id

    attribute :comment, :string, allow_nil?: true, public?: true
    attribute :activity_id, :uuid, allow_nil?: false, public?: true
    attribute :user_id, :uuid, allow_nil?: false, public?: true

    attribute :start_at, :time, allow_nil?: true, public?: true
    attribute :end_at, :time, allow_nil?: true, public?: true

    create_timestamp :created_at, writable?: true
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :activity, Omedis.Accounts.Activity do
      allow_nil? true
      attribute_writable? true
    end

    belongs_to :organisation, Omedis.Accounts.Organisation

    belongs_to :user, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end

    has_many :access_rights, Omedis.Accounts.AccessRight do
      manual Omedis.Accounts.LogEntry.Relationships.LogEntryAccessRights
    end
  end
end
