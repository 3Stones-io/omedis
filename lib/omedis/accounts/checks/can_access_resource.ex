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

  def match?(actor, context, _options) do
    resource = context.resource
    tenant = context.subject.tenant
    resource_name = get_resource_name(resource)
    action = get_action(context)

    cond do
      is_nil(actor) ->
        false

      is_nil(tenant) ->
        false

      tenant.owner_id == actor.id ->
        true

      true ->
        Ash.exists?(
          filter(
            AccessRight,
            resource_name == ^resource_name and tenant_id == ^tenant.id and
              (write == true or ^action == true) and
              exists(group.group_users, user_id == ^actor.id)
          )
        )
    end
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
