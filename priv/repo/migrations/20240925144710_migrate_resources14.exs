defmodule Omedis.Repo.Migrations.MigrateResources14 do
  use Ecto.Migration

  def change do
    """
    execute "ALTER TABLE tenants ALTER COLUMN timezone SET DEFAULT 'GMT+0200 (Europe/Berlin)'"
    """
  end
end
