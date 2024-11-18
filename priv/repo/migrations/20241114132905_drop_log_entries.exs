defmodule Omedis.Repo.Migrations.DropLogEntries do
  use Ecto.Migration

  def up do
    # Drop foreign key constraints first
    drop constraint(:log_entries, "log_entries_organisation_id_fkey")
    drop constraint(:log_entries, "log_entries_user_id_fkey")
    drop constraint(:log_entries, "log_entries_activity_id_fkey")

    # Drop primary key constraint
    drop constraint(:log_entries, "log_entries_pkey")

    # Drop the table
    drop table(:log_entries)
  end

  def down do
    create table(:log_entries, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :comment, :text
      add :start_at, :time
      add :end_at, :time

      add :organisation_id,
          references(:organisations,
            column: :id,
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false

      add :user_id,
          references(:users,
            column: :id,
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false

      add :activity_id,
          references(:activities,
            column: :id,
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          )

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end
  end
end
