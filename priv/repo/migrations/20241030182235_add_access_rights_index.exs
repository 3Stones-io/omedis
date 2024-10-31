defmodule Omedis.Repo.Migrations.AddAccessRightsIndex do
  use Ecto.Migration

  def change do
    create index(:access_rights, [:resource_name, :tenant_id, :group_id])
  end
end
