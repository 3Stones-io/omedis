defmodule Omedis.Repo.Migrations.RenameLogCategories do
  use Ecto.Migration

  def up do
    # Drop existing indices first
    drop_if_exists unique_index(:log_categories, [:color_code, :group_id],
                     name: "log_categories_unique_color_code_position_index"
                   )

    drop_if_exists unique_index(:log_categories, [:position, :group_id],
                     name: "log_categories_unique_position_index"
                   )

    drop_if_exists unique_index(:log_categories, [:slug, :group_id],
                     name: "log_categories_unique_slug_index"
                   )

    # Drop existing foreign key constraints
    drop constraint(:log_categories, "log_categories_group_id_fkey")
    drop constraint(:log_categories, "log_categories_project_id_fkey")
    drop constraint(:log_entries, "log_entries_log_category_id_fkey")

    # Drop primary key constraint
    drop constraint(:log_categories, "log_categories_pkey")

    # Rename the table
    rename table(:log_categories), to: table(:activities)

    # Rename the foreign key column in log_entries
    rename table(:log_entries), :log_category_id, to: :activity_id

    # Re-create foreign key constraints with new names
    alter table(:activities) do
      modify :id, :uuid, primary_key: true
      modify :group_id, references(:groups, type: :uuid, on_delete: :delete_all)
      modify :project_id, references(:projects, type: :uuid, on_delete: :delete_all)
    end

    alter table(:log_entries) do
      modify :activity_id, references(:activities, type: :uuid, on_delete: :delete_all)
    end

    # Re-create indices with new names
    create unique_index(:activities, [:color_code, :group_id],
             name: "activities_unique_color_code_index"
           )

    create unique_index(:activities, [:slug, :group_id], name: "activities_unique_slug_index")
  end

  def down do
    # Drop indices
    drop_if_exists unique_index(:activities, [:color_code, :group_id],
                     name: "activities_unique_color_code_index"
                   )

    drop_if_exists unique_index(:activities, [:position, :group_id],
                     name: "activities_unique_position_index"
                   )

    drop_if_exists unique_index(:activities, [:slug, :group_id],
                     name: "activities_unique_slug_index"
                   )

    # Drop constraints
    drop constraint(:activities, "activities_group_id_fkey")
    drop constraint(:activities, "activities_project_id_fkey")
    drop constraint(:log_entries, "log_entries_activity_id_fkey")

    # Drop primary key constraint
    drop constraint(:activities, "activities_pkey")

    # Rename the table back
    rename table(:activities), to: table(:log_categories)

    # Rename the foreign key column back
    rename table(:log_entries), :activity_id, to: :log_category_id

    # Re-create constraints for the original table
    alter table(:log_categories) do
      modify :id, :uuid, primary_key: true
      modify :group_id, references(:groups, type: :uuid, on_delete: :delete_all)
      modify :project_id, references(:projects, type: :uuid, on_delete: :delete_all)
    end

    alter table(:log_entries) do
      modify :log_category_id, references(:log_categories, type: :uuid, on_delete: :delete_all)
    end

    # Re-create original indices
    create unique_index(:log_categories, [:color_code, :group_id],
             name: "log_categories_unique_color_code_position_index"
           )

    create unique_index(:log_categories, [:slug, :group_id],
             name: "log_categories_unique_slug_index"
           )
  end
end
