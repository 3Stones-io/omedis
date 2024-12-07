defmodule Omedis.Repo.Migrations.NullableUserFields do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :lang, :text, null: true
      modify :birthdate, :date, null: true
      modify :last_name, :text, null: true
      modify :first_name, :text, null: true
    end
  end

  def down do
    alter table(:users) do
      modify :first_name, :text, null: false
      modify :last_name, :text, null: false
      modify :birthdate, :date, null: false
      modify :lang, :text, null: false
    end
  end
end