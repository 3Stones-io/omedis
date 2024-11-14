defmodule Omedis.Accounts.CanUpdateOrganisation do
  @moduledoc """
  Determines whether a user can update an organisation.
  User either needs to be the owner of the organisation or have write access to the organisation through a group.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.AccessRight

  def describe(_options) do
    "User can update organisation if they are the owner or have write access through a group."
  end

  def match?(nil, _context, _opts), do: false
  def match?(_actor, %{subject: %{data: nil}}, _opts), do: false

  def match?(actor, %{subject: %{data: organisation}}, _opts) do
    Ash.exists?(
      filter(
        AccessRight,
        (write || update) && exists(group.group_memberships, user_id == ^actor.id)
      ),
      tenant: organisation
    )
  end
end
