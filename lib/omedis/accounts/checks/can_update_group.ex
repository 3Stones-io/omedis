defmodule Omedis.Accounts.CanUpdateGroup do
  @moduledoc false

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.AccessRight

  def describe(_options) do
    "User can access a resource if they have the access right through a group"
  end

  def match?(nil, _context, _options), do: false

  def match?(_actor, %{subject: %{tenant: nil}}, _options), do: false

  def match?(actor, context, _options) do
    resource = context.resource
    tenant = context.subject.tenant
    resource_name = get_resource_name(resource)
    action = get_action(context)

    Ash.exists?(
      filter(
        AccessRight,
        resource_name == ^resource_name and tenant_id == ^tenant.id and
          (write == true or ^action == true) and
          exists(group.group_users, user_id == ^actor.id)
      )
    ) and tenant.owner_id == actor.id
  end

  defp get_resource_name(resource) do
    resource
    |> Module.split()
    |> List.last()
  end

  defp get_action(context) do
    case context.action do
      %{type: :create} -> :create
      _ -> :update
    end
  end
end
