defmodule Omedis.Repo.Migrations.AddUserIdToChatRoomResource do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:chat_rooms) do
      add :user_id,
          references(:users,
            column: :id,
            name: "chat_rooms_user_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    create index(:chat_rooms, [:organisation_id, :user_id])

    create index(:chat_rooms, [:user_id])
  end

  def down do
    drop constraint(:chat_rooms, "chat_rooms_user_id_fkey")

    drop_if_exists index(:chat_rooms, [:user_id])

    drop_if_exists index(:chat_rooms, [:organisation_id, :user_id])

    alter table(:chat_rooms) do
      remove :user_id
    end
  end
end