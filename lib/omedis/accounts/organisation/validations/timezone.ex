defmodule Omedis.Accounts.Organisation.Validations.Timezone do
  use Ash.Resource.Validation

  @moduledoc """
  This is a module for validating the timezone.
  If the timezone is not in a list of valid timezones, it will return an error.
  """

  @impl true
  def init(opts) do
    case is_atom(opts[:attribute]) do
      true -> {:ok, opts}
      _ -> {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    timezone =
      Ash.Changeset.get_attribute(changeset, opts[:attribute])

    timezones_supported = ["GMT+0200 (Europe/Berlin)"]

    if timezone &&
         timezone not in timezones_supported do
      {:error, field: :username, message: "This is an unsupported timezone"}
    else
      :ok
    end
  end
end
