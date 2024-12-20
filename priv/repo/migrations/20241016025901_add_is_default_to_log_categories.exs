defmodule Omedis.Repo.Migrations.AddIsDefaultToLogCategories do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:log_categories) do
      add :is_default, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:log_categories) do
      remove :is_default
    end
  end
end
