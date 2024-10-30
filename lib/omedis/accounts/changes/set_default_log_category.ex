defmodule Omedis.Accounts.Changes.SetDefaultLogCategory do
  @moduledoc false
  use Ash.Resource.Change

  alias Omedis.Accounts.LogCategory

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &check_and_update_default_log_category/1)
  end

  def check_and_update_default_log_category(changeset) do
    group_id = Ash.Changeset.get_attribute(changeset, :group_id)
    is_default = Ash.Changeset.get_attribute(changeset, :is_default)

    if is_default do
      group_id
      |> LogCategory.get_default_log_category()
      |> maybe_update_previous_default(changeset)
    else
      changeset
    end
  end

  defp maybe_update_previous_default(nil, changeset), do: changeset

  defp maybe_update_previous_default(%LogCategory{} = previous_default, changeset) do
    updated_default =
      previous_default
      |> Ash.Changeset.for_update(:update, %{is_default: false})
      |> Ash.update()

    case updated_default do
      {:ok, _updated_default} ->
        changeset

      {:error, _error} ->
        Ash.Changeset.add_error(
          changeset,
          [:is_default, "Only one default category is allowed per group"]
        )
    end
  end
end