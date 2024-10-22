defmodule Omedis.Accounts.Permissions.GroupReadAccessFilter do
  @moduledoc false

  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering groups based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)

  def filter(actor, context, _options) do
    tenant = context.subject.tenant

    case tenant do
      nil ->
        expr(false)

      tenant ->
        expr(
          exists(
            access_rights,
            tenant_id == ^tenant.id and
              read == true and
              exists(group.group_users, user_id == ^actor.id)
          ) and exists(tenant, id == ^tenant.id)
        )
    end
  end
end
