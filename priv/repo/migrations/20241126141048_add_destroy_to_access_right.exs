defmodule Omedis.Repo.Migrations.AddDestroyToAccessRight do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:access_rights) do
      remove :write
      add :destroy, :boolean, default: false
    end
  end

  def down do
    alter table(:access_rights) do
      remove :destroy
      add :write, :boolean, default: false
    end
  end
end