defmodule Omedis.Repo.Migrations.MigrateResources16 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:projects, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :name, :text, null: false

      add :tenant_id,
          references(:tenants,
            column: :id,
            name: "projects_tenant_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false

      add :position, :text, null: false

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create unique_index(:projects, [:name, :tenant_id], name: "projects_unique_name_index")

    create unique_index(:projects, [:position, :tenant_id],
             name: "projects_unique_position_index"
           )
  end

  def down do
    drop_if_exists unique_index(:projects, [:position, :tenant_id],
                     name: "projects_unique_position_index"
                   )

    drop_if_exists unique_index(:projects, [:name, :tenant_id],
                     name: "projects_unique_name_index"
                   )

    drop constraint(:projects, "projects_tenant_id_fkey")

    drop table(:projects)
  end
end
