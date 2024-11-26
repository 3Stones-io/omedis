defmodule Omedis.Accounts.Changes.UpdateActivityPositions do
  @moduledoc false
  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Accounts.Activity

  @impl true
  def change(changeset, _opts, context) do
    actor = context.actor
    organisation = context.tenant
    old_position = changeset.data.position
    group_id = Ash.Changeset.get_attribute(changeset, :group_id)
    requested_position = Ash.Changeset.get_attribute(changeset, :position)

    activity_to_shift =
      Activity
      |> Ash.Query.filter(group_id == ^group_id and position == ^requested_position)
      |> Ash.read_one!(actor: actor, tenant: organisation)

    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      max_position =
        Activity
        |> Ash.Query.filter(group_id == ^group_id)
        |> Ash.count!(actor: actor, tenant: organisation)

      shift_activity_position(
        activity_to_shift,
        max_position + 1,
        organisation,
        actor
      )

      changeset
    end)
    |> Ash.Changeset.after_action(fn _changeset, result ->
      shift_activity_position(
        activity_to_shift,
        old_position,
        organisation,
        actor
      )

      {:ok, result}
    end)
  end

  defp shift_activity_position(activity, new_position, organisation, actor) do
    Activity.update(
      activity,
      %{position: new_position},
      actor: actor,
      tenant: organisation
    )
  end
end
