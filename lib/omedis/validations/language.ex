defmodule Omedis.Validations.Language do
  use Ash.Resource.Validation

  @moduledoc """
  This is a module for validating the language.
  If the language is not in a list of valid languages, it will return an error.
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
    language =
      Ash.Changeset.get_attribute(changeset, opts[:attribute])

    languages_supported = ["en", "de", "fr", "it"]

    if language &&
         language not in languages_supported do
      {:error, field: :username, message: "This is an unsupported language"}
    else
      :ok
    end
  end
end
