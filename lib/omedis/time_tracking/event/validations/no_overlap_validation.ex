defmodule Omedis.TimeTracking.Event.Validations.NoOverlapValidation do
  @moduledoc """
  Validates that an event does not overlap with another event for the same user.
  """

  use Ash.Resource.Validation

  require Ash.Query

  @impl true
  def validate(changeset, _opts, context) do
    case {Ash.Changeset.get_attribute(changeset, :dtstart),
          Ash.Changeset.get_attribute(changeset, :user_id)} do
      {nil, _} ->
        :ok

      {_, nil} ->
        :ok

      {dtstart, user_id} ->
        validate_no_overlap(changeset, dtstart, user_id,
          actor: context.actor,
          tenant: context.tenant
        )
    end
  end

  defp validate_no_overlap(changeset, dtstart, user_id, opts) do
    query =
      Omedis.TimeTracking.Event
      |> Ash.Query.filter(user_id == ^user_id)
      |> filter_where_event_id_is_not_changeset_data_id(changeset)
      |> Ash.Query.filter(dtend >= ^dtstart or is_nil(dtend))

    case Ash.read(query, opts) do
      {:ok, []} ->
        :ok

      {:ok, _overlapping_events} ->
        {:error,
         field: :dtstart, message: "cannot create an event that overlaps with another event"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp filter_where_event_id_is_not_changeset_data_id(query, changeset) do
    case changeset.data.id do
      nil ->
        query

      id ->
        Ash.Query.filter(query, id != ^id)
    end
  end
end
