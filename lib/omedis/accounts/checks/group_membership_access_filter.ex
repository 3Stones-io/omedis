defmodule Omedis.Accounts.GroupMembershipAccessFilter do
  @moduledoc """
  This policy filter is used to filter group_memberships based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering group_memberships based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)

  def filter(actor, context, _options) do
    tenant = context.subject.tenant

    case tenant do
      nil ->
        expr(false)

      tenant ->
        expr(
          (exists(
             access_rights,
             tenant_id == ^tenant.id and
               read == true and
               exists(group.group_memberships, user_id == ^actor.id)
           ) and
             exists(group, tenant_id == ^tenant.id)) or
            group.tenant.owner_id == ^actor.id
        )
    end
  end
end
