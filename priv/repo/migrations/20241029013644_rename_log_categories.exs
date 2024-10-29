defmodule Omedis.Repo.Migrations.RenameLogCategories do
  use Ecto.Migration

  def up do
    drop_if_exists index(:log_categories, [:slug, :group_id],
                     name: "log_categories_unique_slug_index"
                   )

    drop_if_exists index(:log_categories, [:position, :group_id],
                     name: "log_categories_unique_position_index"
                   )

    drop_if_exists index(:log_categories, [:color_code, :group_id],
                     name: "log_categories_unique_color_code_position_index"
                   )

    drop constraint(:log_entries, "log_entries_log_category_id_fkey")

    execute "ALTER TABLE log_categories DROP CONSTRAINT log_categories_pkey"
    execute "ALTER TABLE log_categories ADD CONSTRAINT activities_pkey PRIMARY KEY (id)"

    rename table(:log_categories), to: table(:activities)
    rename table(:log_entries), :log_category_id, to: :activity_id

    alter table(:log_entries) do
      modify :activity_id,
             references(:activities,
               column: :id,
               name: "log_entries_activity_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    create unique_index(:activities, [:color_code, :group_id],
             name: "activities_unique_color_code_position_index"
           )

    create unique_index(:activities, [:position, :group_id],
             name: "activities_unique_position_index"
           )

    create unique_index(:activities, [:slug, :group_id], name: "activities_unique_slug_index")
  end

  def down do
    drop_if_exists index(:activities, [:slug, :group_id], name: "activities_unique_slug_index")

    drop_if_exists index(:activities, [:position, :group_id],
                     name: "activities_unique_position_index"
                   )

    drop_if_exists index(:activities, [:color_code, :group_id],
                     name: "activities_unique_color_code_position_index"
                   )

    drop constraint(:log_entries, "log_entries_activity_id_fkey")

    execute "ALTER TABLE activities DROP CONSTRAINT activities_pkey"
    execute "ALTER TABLE activities ADD CONSTRAINT log_categories_pkey PRIMARY KEY (id)"

    rename table(:log_entries), :activity_id, to: :log_category_id
    rename table(:activities), to: table(:log_categories)

    alter table(:log_entries) do
      modify :log_category_id,
             references(:log_categories,
               column: :id,
               name: "log_entries_log_category_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    create unique_index(:log_categories, [:color_code, :group_id],
             name: "log_categories_unique_color_code_position_index"
           )

    create unique_index(:log_categories, [:position, :group_id],
             name: "log_categories_unique_position_index"
           )

    create unique_index(:log_categories, [:slug, :group_id],
             name: "log_categories_unique_slug_index"
           )
  end
end
