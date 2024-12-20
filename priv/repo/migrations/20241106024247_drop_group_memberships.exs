defmodule Omedis.Repo.Migrations.DropGroupMemberships do
  use Ecto.Migration

  def up do
    drop_if_exists unique_index(:group_memberships, [:group_id, :user_id],
                     name: "group_memberships_unique_group_member_index"
                   )

    drop constraint(:group_memberships, "group_memberships_group_id_fkey")
    drop constraint(:group_memberships, "group_memberships_user_id_fkey")

    drop table(:group_memberships)
  end

  def down do
    create table(:group_memberships, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :group_id,
          references(:groups,
            column: :id,
            name: "group_memberships_group_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          primary_key: true,
          null: false

      add :user_id,
          references(:users,
            column: :id,
            name: "group_memberships_user_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          primary_key: true,
          null: false
    end

    create unique_index(:group_memberships, [:group_id, :user_id],
             name: "group_memberships_unique_group_member_index"
           )
  end
end
