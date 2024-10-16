defmodule Omedis.Validations.DefaultLogCategory do
  @moduledoc """
  Validates that there can only be one default `log_category` per group.
  """
  use Ash.Resource.Validation

  alias Omedis.Accounts.LogCategory

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    group_id = Ash.Changeset.get_attribute(changeset, :group_id)
    is_default = Ash.Changeset.get_attribute(changeset, :is_default)

    if is_default do
      query = Ash.Query.filter(LogCategory, group_id: group_id, is_default: true)

      case Ash.read(query) do
        {:ok, []} ->
          :ok

        {:ok, _category} ->
          {:error, "Only one default category is allowed per group"}

        {:error, error} ->
          {:error, error}
      end
    else
      :ok
    end
  end
end
