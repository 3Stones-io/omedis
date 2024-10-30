defmodule Omedis.Repo.Migrations.CopyLogCategoriesDataToActivites do
  use Ecto.Migration

  def change do
    execute(
      """
      INSERT INTO activities (
        id, name, group_id, project_id, color_code,
        is_default, position, slug, created_at, updated_at
      )
      SELECT
        id, name, group_id, project_id, color_code,
        is_default, position, slug, created_at, updated_at
      FROM log_categories;
      """,
      """
      DELETE FROM activities
      WHERE id IN (SELECT id FROM log_categories);
      """
    )
  end
end
