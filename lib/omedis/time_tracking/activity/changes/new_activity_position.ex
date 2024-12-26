defmodule Omedis.TimeTracking.Activity.Changes.NewActivityPosition do
  @moduledoc false

  use Ash.Resource.Change

  alias Omedis.TimeTracking.Activity

  @impl true
  def change(changeset, _opts, %{tenant: organisation} = _context) do
    Ash.Changeset.before_action(changeset, &generate_activity_position(&1, organisation))
  end

  defp generate_activity_position(changeset, organisation) do
    case Ash.Changeset.get_attribute(changeset, :group_id) do
      group_id when is_binary(group_id) ->
        query = Ash.Query.filter(Activity, group_id == ^group_id)

        position =
          case Ash.max(query, :position, authorize?: false, tenant: organisation) do
            {:ok, max_position} when is_integer(max_position) ->
              max_position + 1

            _ ->
              1
          end

        Ash.Changeset.change_attribute(changeset, :position, position)

      _ ->
        Ash.Changeset.add_error(changeset, [:position, "Position is required"])
    end
  end
end
