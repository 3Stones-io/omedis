defmodule Omedis.Repo.Migrations.AddIdToGroupUsers do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE group_users DROP CONSTRAINT group_users_pkey"

    alter table(:group_users) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end
  end

  def down do
    alter table(:group_users) do
      remove :id
    end

    execute "ALTER TABLE group_users ADD PRIMARY KEY (group_id, user_id)"
  end
end
