defmodule Omedis.Repo.Migrations.MigrateResources6 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:log_categories) do
      add :color_code, :text
      add :position, :text
    end

    create unique_index(:log_categories, [:color_code, :tenant_id],
             name: "log_categories_unique_color_code_position_index"
           )

    create unique_index(:log_categories, [:position, :tenant_id],
             name: "log_categories_unique_position_index"
           )
  end

  def down do
    drop_if_exists unique_index(:log_categories, [:position, :tenant_id],
                     name: "log_categories_unique_position_index"
                   )

    drop_if_exists unique_index(:log_categories, [:color_code, :tenant_id],
                     name: "log_categories_unique_color_code_position_index"
                   )

    alter table(:log_categories) do
      remove :position
      remove :color_code
    end
  end
end
