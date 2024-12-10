defmodule Omedis.Accounts.CanCreateOrganisation do
  @moduledoc """
  Determines whether a user can create an organisation.
  User can create only one organisation.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  def describe(_options) do
    "User can create only one organisation."
  end

  def match?(nil, _context, _options), do: false

  def match?(%User{current_organisation_id: nil} = _actor, _context, _options) do
    true
  end

  def match?(actor, _context, _options) do
    !Ash.exists?(filter(Organisation, owner_id == ^actor.id), authorize?: false)
  end
end
