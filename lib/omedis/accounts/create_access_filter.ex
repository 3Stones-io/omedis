defmodule Omedis.Accounts.CreateAccessFilter do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  require Ash.Query

  alias Omedis.Accounts.AccessRight

  def describe(_) do
    "user must have create access to the resource"
  end

  def match?(nil, _context, _opts), do: false

  def match?(actor, context, _opts) do
    tenant = context.subject.tenant
    resource_name = get_resource_name(context.resource)

    case tenant do
      nil ->
        false

      tenant ->
        AccessRight
        |> Ash.Query.filter(
          tenant_id == ^tenant.id and resource_name == ^resource_name and create == true
        )
        |> Ash.Query.filter(exists(group.group_users, user_id == ^actor.id))
        |> Ash.exists?()
    end
  end

  defp get_resource_name(resource) do
    resource
    |> Module.split()
    |> List.last()
  end
end
