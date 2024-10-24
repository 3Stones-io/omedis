defmodule Omedis.Accounts.CanCreateTenant do
  @moduledoc """
  Determines whether a user can create a tenant.
  User can create only one tenant.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Tenant

  def describe(_options) do
    "User can create only one tenant."
  end

  def match?(actor, _context, _options) do
    !Ash.exists?(filter(Tenant, owner_id == ^actor.id), authorize?: false)
  end
end
