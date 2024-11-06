defmodule Omedis.Repo.Migrations.RenameGroupUsers do
  @moduledoc """
  Renames the group_users table to group_memberships and updates constraints and indexes.
  """

  use Ecto.Migration

  def up do
    drop constraint(:group_users, "group_users_user_id_fkey")
    drop constraint(:group_users, "group_users_group_id_fkey")

    drop_if_exists unique_index(:group_users, [:group_id, :user_id],
                     name: "group_users_unique_group_user_index"
                   )

    execute "ALTER TABLE group_users DROP CONSTRAINT group_users_pkey"

    rename table(:group_users), to: table(:group_memberships)

    alter table(:group_memberships) do
      modify :group_id,
             references(:groups,
               column: :id,
               name: "group_memberships_group_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )

      modify :user_id,
             references(:users,
               column: :id,
               name: "group_memberships_user_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    execute "ALTER TABLE group_memberships ADD PRIMARY KEY (group_id, user_id)"

    create unique_index(:group_memberships, [:group_id, :user_id],
             name: "group_memberships_unique_group_membership_index"
           )
  end

  def down do
    drop_if_exists unique_index(:group_memberships, [:group_id, :user_id],
                     name: "group_memberships_unique_group_membership_index"
                   )

    drop constraint(:group_memberships, "group_memberships_group_id_fkey")
    drop constraint(:group_memberships, "group_memberships_user_id_fkey")
    execute "ALTER TABLE group_memberships DROP CONSTRAINT group_memberships_pkey"

    rename table(:group_memberships), to: table(:group_users)

    alter table(:group_users) do
      modify :user_id,
             references(:users,
               column: :id,
               name: "group_users_user_id_fkey",
               type: :uuid,
               prefix: "public"
             )

      modify :group_id,
             references(:groups,
               column: :id,
               name: "group_users_group_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    execute "ALTER TABLE group_users ADD PRIMARY KEY (group_id, user_id)"

    create unique_index(:group_users, [:group_id, :user_id],
             name: "group_users_unique_group_user_index"
           )
  end
end
