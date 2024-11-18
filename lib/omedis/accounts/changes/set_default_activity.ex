defmodule Omedis.Accounts.Changes.SetDefaultActivity do
  @moduledoc false
  use Ash.Resource.Change

  alias Omedis.Accounts.Activity

  @impl true
  def change(changeset, _opts, %{actor: actor, tenant: organisation} = _context) do
    Ash.Changeset.before_action(
      changeset,
      &check_and_update_default_activity(&1, organisation, actor)
    )
  end

  def check_and_update_default_activity(changeset, organisation, actor) do
    group_id = Ash.Changeset.get_attribute(changeset, :group_id)
    is_default = Ash.Changeset.get_attribute(changeset, :is_default)

    if is_default do
      Activity
      |> Ash.Query.filter(group_id: group_id, is_default: true)
      |> Ash.read_one!(authorize?: false, tenant: organisation)
      |> maybe_update_previous_default(changeset, organisation, actor)
    else
      changeset
    end
  end

  defp maybe_update_previous_default(nil, changeset, _organisation, _actor), do: changeset

  defp maybe_update_previous_default(
         %Activity{} = previous_default,
         changeset,
         organisation,
         actor
       ) do
    updated_default =
      previous_default
      |> Ash.Changeset.for_update(:update, %{is_default: false},
        tenant: organisation,
        actor: actor
      )
      |> Ash.update()

    case updated_default do
      {:ok, _updated_default} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(
          changeset,
          [:is_default, "Only one default activity is allowed per group"]
        )
    end
  end
end
