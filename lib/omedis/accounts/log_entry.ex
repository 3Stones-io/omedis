defmodule Omedis.Accounts.LogEntry do
  @moduledoc """
  This is the log entry module
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  postgres do
    table "log_entries"
    repo Omedis.Repo

    references do
      reference :tenant, on_delete: :delete
      reference :log_category, on_delete: :delete
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
    define :destroy
    define :by_log_category
    define :by_log_category_today
    define :by_tenant
    define :by_tenant_today
    define :by_id, get_by: [:id], action: :read
  end

  actions do
    read :by_log_category do
      argument :log_category_id, :uuid do
        allow_nil? false
      end

      filter expr(log_category_id == ^arg(:log_category_id))
    end

    read :by_tenant do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      filter expr(tenant_id == ^arg(:tenant_id))
    end

    read :by_tenant_today do
      argument :tenant_id, :uuid do
        allow_nil? false
      end

      filter expr(
               tenant_id == ^arg(:tenant_id) and
                 fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at)
             )
    end

    read :by_log_category_today do
      argument :log_category_id, :uuid do
        allow_nil? false
      end

      filter expr(
               log_category_id == ^arg(:log_category_id) and
                 fragment("date_trunc('day', ?) = date_trunc('day', now())", created_at)
             )
    end

    create :create do
      accept [
        :comment,
        :start_at,
        :end_at,
        :tenant_id,
        :log_category_id,
        :user_id
      ]

      primary? true
    end

    update :update do
      accept [
        :comment,
        :start_at,
        :end_at,
        :tenant_id,
        :log_category_id,
        :user_id
      ]

      primary? true
      require_atomic? false
    end

    read :read do
      primary? true
    end

    destroy :destroy do
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :comment, :string, allow_nil?: true, public?: true
    attribute :tenant_id, :uuid, allow_nil?: false, public?: true
    attribute :log_category_id, :uuid, allow_nil?: false, public?: true
    attribute :user_id, :uuid, allow_nil?: false, public?: true

    attribute :start_at, :time, allow_nil?: true, public?: true
    attribute :end_at, :time, allow_nil?: true, public?: true

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tenant, Omedis.Accounts.Tenant do
      allow_nil? true
      attribute_writable? true
    end

    belongs_to :log_category, Omedis.Accounts.LogCategory do
      allow_nil? true
      attribute_writable? true
    end

    belongs_to :user, Omedis.Accounts.User do
      allow_nil? true
      attribute_writable? true
    end
  end
end