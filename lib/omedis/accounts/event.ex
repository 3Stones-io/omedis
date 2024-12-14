defmodule Omedis.Accounts.Event do
  @moduledoc """
  This is the event module
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "events"
    repo Omedis.Repo

    references do
      reference :activity, on_delete: :delete
      reference :organisation, on_delete: :delete
      reference :user, on_delete: :delete
    end
  end

  resource do
    plural_name :events
  end

  code_interface do
    domain Omedis.Accounts
    define :by_activity
    define :by_activity_today
    define :create
    define :list_paginated
    define :list_paginated_today
    define :read
    define :update
  end

  actions do
    create :create do
      accept [
        :activity_id,
        :dtend,
        :dtstart,
        :summary,
        :user_id
      ]

      primary? true

      change fn changeset, _ ->
        case changeset.context do
          %{created_at: created_at} ->
            Ash.Changeset.change_attribute(changeset, :created_at, created_at)

          _ ->
            changeset
        end
      end
    end

    read :by_activity do
      argument :activity_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(sort: :created_at)
      prepare build(load: [:dtstamp, :uid, :duration_minutes])

      filter expr(activity_id == ^arg(:activity_id))
    end

    read :by_activity_today do
      argument :activity_id, :uuid do
        allow_nil? false
      end

      prepare build(load: [:dtstamp, :uid, :duration_minutes])

      filter expr(
               activity_id == ^arg(:activity_id) and
                 fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at)
             )
    end

    read :list_paginated do
      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(sort: :created_at)
      prepare build(load: [:dtstamp, :uid, :duration_minutes])
    end

    read :list_paginated_today do
      pagination offset?: true,
                 default_limit: Application.compile_env(:omedis, :pagination_default_limit),
                 countable: :by_default

      prepare build(sort: :created_at)
      prepare build(load: [:dtstamp, :uid, :duration_minutes])

      filter expr(fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at))
    end

    read :read do
      primary? true
      prepare build(load: [:dtstamp, :uid, :duration_minutes])
    end

    update :update do
      accept [
        :activity_id,
        :dtend,
        :dtstart,
        :summary,
        :user_id
      ]

      primary? true
      require_atomic? false
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if Omedis.AccessRights.AccessRight.AccessFilter
    end

    policy action_type([:create, :update]) do
      authorize_if Omedis.AccessRights.AccessRight.CanAccessResource
    end
  end

  validations do
    validate compare(:dtend, greater_than: :dtstart),
      where: [attribute_does_not_equal(:dtend, nil)],
      message: "end date must be greater than the start date"

    validate {Omedis.Accounts.Event.Validations.NoOverlapValidation, []}
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  attributes do
    uuid_primary_key :id

    attribute :activity_id, :uuid, allow_nil?: false, public?: true
    attribute :dtend, :utc_datetime_usec, allow_nil?: true, public?: true
    attribute :dtstart, :utc_datetime_usec, allow_nil?: false, public?: true
    attribute :summary, :string, allow_nil?: false, public?: true
    attribute :user_id, :uuid, allow_nil?: false, public?: true

    create_timestamp :created_at, writable?: true
    create_timestamp :updated_at, writable?: true
  end

  relationships do
    belongs_to :activity, Omedis.Accounts.Activity
    belongs_to :organisation, Omedis.Accounts.Organisation
    belongs_to :user, Omedis.Accounts.User

    has_many :access_rights, Omedis.AccessRights.AccessRight do
      manual Omedis.Accounts.Event.Relationships.EventAccessRights
    end
  end

  calculations do
    calculate :dtstamp, :utc_datetime_usec, expr(updated_at)
    calculate :uid, :string, expr(id)

    calculate :duration_minutes,
              :integer,
              {Omedis.Accounts.Event.Calculations.CalculateDuration, [:dtend, :dtstart]}
  end
end
