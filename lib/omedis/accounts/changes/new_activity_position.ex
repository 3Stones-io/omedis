defmodule Omedis.Accounts.Changes.NewActivityPosition do
  @moduledoc false

  use Ash.Resource.Change

  alias Omedis.Accounts.Activity

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &generate_activity_position/1)
  end

  defp generate_activity_position(changeset) do
    case Ash.Changeset.get_attribute(changeset, :group_id) do
      group_id when is_binary(group_id) ->
        max_position =
          Activity
          |> Ash.Query.filter(group_id == ^group_id)
          |> Ash.count!()

        Ash.Changeset.change_attribute(changeset, :position, max_position + 1)

      _ ->
        Ash.Changeset.add_error(changeset, [:position, "Position is required"])
    end
  end
end
