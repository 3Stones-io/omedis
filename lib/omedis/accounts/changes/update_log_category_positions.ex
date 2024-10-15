defmodule Omedis.Accounts.Changes.UpdateLogCategoryPositions do
  @moduledoc false

  use Ash.Resource.Change

  import Ecto.Query, warn: false

  @impl true
  def change(changeset, opts, _context) do
    log_category = changeset.data
    old_position = log_category.position
    new_idx = if(opts[:direction] == :inc, do: old_position - 1, else: old_position + 1)

    Ecto.Multi.new()
    |> multi_reposition(:new, log_category, new_idx)
    |> Omedis.Repo.transaction()

    changeset
  end

  defp multi_reposition(%Ecto.Multi{} = multi, name, %type{} = struct, new_idx) do
    old_position = from(og in type, where: og.id == ^struct.id, select: og.position)

    multi
    |> Ecto.Multi.run({:index, name}, fn repo, _changes ->
      case repo.one(from(t in type, select: count(t.id))) do
        count when new_idx < count -> {:ok, new_idx}
        count -> {:ok, count - 1}
      end
    end)
    |> multi_update_all({:dec_positions, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: t.id != ^struct.id,
        where: t.position > subquery(old_position) and t.position <= ^computed_index,
        update: [inc: [position: -1]]
      )
    end)
    |> multi_update_all({:inc_positions, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: t.id != ^struct.id,
        where: t.position < subquery(old_position) and t.position >= ^computed_index,
        update: [inc: [position: 1]]
      )
    end)
    |> multi_update_all({:position, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: t.id == ^struct.id,
        update: [set: [position: ^computed_index]]
      )
    end)
  end

  defp multi_update_all(multi, name, func, opts \\ []) do
    Ecto.Multi.update_all(multi, name, func, opts)
  end
end
