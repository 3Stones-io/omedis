defmodule Omedis.Accounts.TenantsAccessFilter do
  @moduledoc """
  This policy filter is used to filter tenants based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering tenants based on user access rights"
  end

  def filter(actor, _context, _options) do
    expr(
      exists(
        access_rights,
        resource_name == "Tenant" and
          read == true and
          exists(group.group_users, user_id == ^actor.id)
      ) or
        owner_id == ^actor.id
    )
  end
end
