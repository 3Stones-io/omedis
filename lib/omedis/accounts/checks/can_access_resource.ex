defmodule Omedis.Accounts.CanAccessResource do
  @moduledoc """
  A policy that checks if a user can access a resource.
  """

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.AccessRight

  def describe(_options) do
    "User can access a resource if they have the access right through a group"
  end

  def match?(nil, _context, _options), do: false
  def match?(_actor, %{subject: %{tenant: nil}}, _options), do: false

  def match?(actor, %{subject: %{tenant: tenant}}, _options) when actor.id == tenant.owner_id do
    true
  end

  def match?(actor, %{subject: %{tenant: tenant, resource: resource}} = context, _options) do
    resource_name = get_resource_name(resource)
    action = get_action(context)

    Ash.exists?(
      filter(
        AccessRight,
        resource_name == ^resource_name and tenant_id == ^tenant.id and
          (write == true or ^action == true) and
          exists(group.group_memberships, user_id == ^actor.id)
      )
    )
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
