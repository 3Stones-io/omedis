defmodule Omedis.Accounts.Changes.NewLogCategoryPosition do
  @moduledoc false

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &generate_category_position/1)
  end

  defp generate_category_position(changeset) do
    case Ash.Changeset.get_attribute(changeset, :group_id) do
      group_id when is_binary(group_id) ->
        position = Omedis.Accounts.LogCategory.get_max_position_by_group_id(group_id) + 1

        Ash.Changeset.change_attribute(changeset, :position, position)

      _other ->
        Ash.Changeset.add_error(changeset, [:position, "Position is required"])
    end
  end
end
