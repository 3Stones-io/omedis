defmodule Omedis.Repo.Migrations.MigrateResources15 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:tenants) do
      modify :timezone, :text, null: false, default: "GMT+0200 (Europe/Berlin)"
    end
  end

  def down do
    alter table(:tenants) do
      modify :timezone, :text, null: true, default: nil
    end
  end
end
