defmodule Omedis.Accounts.Organisation.Checks.OrganisationsAccessFilter do
  @moduledoc """
  This policy filter is used to filter organisations based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering organisations based on user access rights"
  end

  def filter(actor, _context, _options) do
    expr(
      exists(
        access_rights,
        resource_name == "Organisation" and
          read == true and
          exists(group.group_memberships, user_id == ^actor.id)
      ) or
        owner_id == ^actor.id
    )
  end
end
