defmodule Omedis.Accounts.Changes.UpdateLogCategoryPositions do
  use Ash.Resource.Change

  alias Omedis.Accounts.LogCategory

  @impl true
  def change(changeset, _, _) do
    id = changeset.data.id
    old_position = changeset.data.position
    new_position = Ash.Changeset.get_argument(changeset, :new_position)

    # change the target column to it's new position
    changeset
    |> Ash.Changeset.change_attribute(:position, new_position)
    |> Ash.update!()

    # temporarily disable unique constraint checks
    Ash.Changeset.before_action(changeset, fn changeset ->
      Omedis.Repo.query("SET CONSTRAINTS unique_order DEFERRED")

      changeset
    end)

    Ash.Changeset.after_action(changeset, fn _changeset, results ->
      # swapping positions with record that had the old position
      log_category =
        LogCategory
        |> Ash.Query.filter(position == ^new_position and id != ^id)
        |> Ash.read_one()
        |> IO.inspect()

      case log_category do
        {:ok, log} ->
          Ash.update!(log, %{position: old_position})

        _else ->
          :do_nothing
      end

      {:ok, results}
    end)
  end
end
