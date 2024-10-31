defmodule Omedis.Repo.Migrations.CopyGroupUsersDataToGroupMemberships do
  use Ecto.Migration

  def change do
    execute(
      """
      INSERT INTO group_memberships (
        id, group_id, user_id
      )
      SELECT
        id, group_id, user_id
      FROM group_users;
      """,
      """
      DELETE FROM group_users
      WHERE id IN (SELECT id FROM group_memberships);
      """
    )
  end
end
