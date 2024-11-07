defmodule Omedis.Repo.Migrations.RenameTenants do
  @moduledoc """
  Renames tenants table to organisations and updates all related constraints, references,
  and column names to maintain consistency across the application.
  """

  use Ecto.Migration

  def up do
    # Drop all existing foreign key constraints
    tables = [:access_rights, :groups, :invitations, :log_entries, :projects]

    for table <- tables do
      drop constraint(table, "#{table}_tenant_id_fkey")
    end

    # Drop existing indexes
    drop_if_exists unique_index(:tenants, [:slug], name: "tenants_unique_slug_index")

    drop_if_exists unique_index(:projects, [:name, :tenant_id],
                     name: "projects_unique_name_index"
                   )

    drop_if_exists unique_index(:projects, [:position, :tenant_id],
                     name: "projects_unique_position_index"
                   )

    drop_if_exists unique_index(:groups, [:slug, :tenant_id],
                     name: "groups_unique_slug_per_tenant_index"
                   )

    rename table(:tenants), to: table(:organisations)

    create unique_index(:organisations, [:slug], name: "organisations_unique_slug_index")

    rename table(:users), :current_tenant_id, to: :current_organisation_id

    # Update all related tables to reference organisations and rename tenant_id columns
    for table <- tables do
      rename table(table), :tenant_id, to: :organisation_id

      alter table(table) do
        modify :organisation_id,
               references(:organisations,
                 column: :id,
                 name: "#{table}_organisation_id_fkey",
                 type: :uuid,
                 prefix: "public",
                 on_delete: :delete_all
               )
      end
    end

    # Recreate unique indexes with new column names
    create unique_index(:projects, [:name, :organisation_id], name: "projects_unique_name_index")

    create unique_index(:projects, [:position, :organisation_id],
             name: "projects_unique_position_index"
           )

    create unique_index(:groups, [:slug, :organisation_id],
             name: "groups_unique_slug_per_organisation_index"
           )
  end

  def down do
    # Drop all new foreign key constraints
    tables = [:access_rights, :groups, :invitations, :log_entries, :projects]

    for table <- tables do
      drop constraint(table, "#{table}_organisation_id_fkey")
    end

    # Drop new indexes
    drop_if_exists unique_index(:projects, [:position, :organisation_id],
                     name: "projects_unique_position_index"
                   )

    drop_if_exists unique_index(:projects, [:name, :organisation_id],
                     name: "projects_unique_name_index"
                   )

    drop_if_exists unique_index(:groups, [:slug, :organisation_id],
                     name: "groups_unique_slug_per_organisation_index"
                   )

    drop_if_exists unique_index(:organisations, [:slug], name: "organisations_unique_slug_index")

    rename table(:organisations), to: table(:tenants)

    rename table(:users), :current_organisation_id, to: :current_tenant_id

    # Revert all related tables
    for table <- tables do
      rename table(table), :organisation_id, to: :tenant_id

      alter table(table) do
        modify :tenant_id,
               references(:tenants,
                 column: :id,
                 name: "#{table}_tenant_id_fkey",
                 type: :uuid,
                 prefix: "public",
                 on_delete: :delete_all
               )
      end
    end

    # Recreate original unique indexes
    create unique_index(:projects, [:position, :tenant_id],
             name: "projects_unique_position_index"
           )

    create unique_index(:projects, [:name, :tenant_id], name: "projects_unique_name_index")
    create unique_index(:groups, [:slug, :tenant_id], name: "groups_unique_slug_per_tenant_index")
    create unique_index(:tenants, [:slug], name: "tenants_unique_slug_index")
  end
end
