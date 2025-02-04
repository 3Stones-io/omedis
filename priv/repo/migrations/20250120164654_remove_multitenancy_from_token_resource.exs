defmodule Omedis.Repo.Migrations.RemoveMultitenancyFromTokenResource do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:tokens) do
      remove :organisation_id
    end
  end

  def down do
    alter table(:tokens) do
      add :organisation_id,
          references(:organisations,
            column: :id,
            name: "tokens_organisation_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          )
    end
  end
end
