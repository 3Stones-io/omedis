defmodule Omedis.Accounts.AccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)

  def filter(actor, context, _options) do
    tenant = context.subject.tenant

    resource =
      context.resource
      |> to_string()
      |> String.split(".")
      |> List.last()

    case tenant do
      nil ->
        expr(false)

      tenant ->
        expr(
          exists(
            access_rights,
            tenant_id == ^tenant.id and
              resource_name == ^resource and
              (create or read or write or update) and
              exists(group.group_users, user_id == ^actor.id)
          ) and exists(tenant, id == ^tenant.id)
        )
    end
  end
end
