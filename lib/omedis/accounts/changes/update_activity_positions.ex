defmodule Omedis.Accounts.Changes.UpdateActivityPositions do
  @moduledoc false
  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Accounts.Activity

  @impl true
  def change(changeset, _opts, context) do
    actor = context.actor
    organisation = context.tenant

    Ash.Changeset.before_action(changeset, fn changeset ->
      requested_position = Ash.Changeset.get_attribute(changeset, :position)
      old_position = changeset.data.position

      max_position =
        Activity
        |> Ash.Query.filter(group_id == ^Ash.Changeset.get_attribute(changeset, :group_id))
        |> Ash.count!(actor: actor, tenant: organisation)

      new_position = min(requested_position, max_position)

      with %Ash.BulkResult{status: :success} <-
             shift_down(old_position, new_position, organisation, actor),
           %Ash.BulkResult{status: :success} <-
             shift_up(old_position, new_position, organisation, actor) do
        changeset
      else
        %Ash.BulkResult{errors: errors} ->
          Ash.Changeset.add_error(changeset, errors)
      end

      changeset
    end)
  end

  defp shift_down(old_position, new_position, organisation, actor) do
    Activity
    |> Ash.Query.filter(position > ^old_position and position <= ^new_position)
    |> Ash.bulk_update!(:decrement_position, %{},
      strategy: :stream,
      actor: actor,
      tenant: organisation
    )
  end

  defp shift_up(old_position, new_position, organisation, actor) do
    Activity
    |> Ash.Query.filter(position < ^old_position and position >= ^new_position)
    |> Ash.bulk_update!(:increment_position, %{},
      strategy: :stream,
      actor: actor,
      tenant: organisation
    )
  end
end
