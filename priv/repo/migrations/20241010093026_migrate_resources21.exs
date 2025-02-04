defmodule Omedis.Repo.Migrations.MigrateResources21 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:log_categories) do
      add :project_id,
          references(:projects,
            column: :id,
            name: "log_categories_project_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          )
    end
  end

  def down do
    drop constraint(:log_categories, "log_categories_project_id_fkey")

    alter table(:log_categories) do
      remove :project_id
    end
  end
end
