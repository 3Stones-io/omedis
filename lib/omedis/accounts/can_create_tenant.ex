defmodule Omedis.Accounts.CanCreateOrganisation do
  @moduledoc """
  Determines whether a user can create a organisation.
  User can create only one organisation.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Organisation

  def describe(_options) do
    "User can create only one organisation."
  end

  def match?(actor, _context, _options) do
    !Ash.exists?(filter(Organisation, owner_id == ^actor.id), authorize?: false)
  end
end
