defmodule Omedis.Repo.Migrations.ActivityPositionIndex do
  use Ecto.Migration

  def up do
    drop_if_exists unique_index(:activities, [:position, :group_id],
                     name: "activities_unique_position_index"
                   )

    create unique_index(:activities, [:organisation_id, :position, :group_id],
             name: "activities_unique_position_index"
           )
  end

  def down do
    drop_if_exists unique_index(:activities, [:organisation_id, :position, :group_id],
                     name: "activities_unique_position_index"
                   )

    create unique_index(:activities, [:position, :group_id],
             name: "activities_unique_position_index"
           )
  end
end
