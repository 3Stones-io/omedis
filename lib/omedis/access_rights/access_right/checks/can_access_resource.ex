defmodule Omedis.AccessRights.AccessRight.CanAccessResource do
  @moduledoc """
  A policy that checks if a user can access a resource.
  """

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.AccessRights.AccessRight

  def describe(_options) do
    "User can access a resource if they have the access right through a group"
  end

  def match?(nil, _context, _options), do: false
  def match?(_actor, %{subject: %{tenant: nil}}, _options), do: false

  def match?(
        actor,
        %{subject: %{tenant: organisation, resource: resource, action: %{type: action}}} =
          _context,
        _options
      ) do
    resource_name = get_resource_name(resource)

    AccessRight
    |> filter(
      resource_name == ^resource_name and exists(group.group_memberships, user_id == ^actor.id)
    )
    |> filter_by_action(action)
    |> Ash.exists?(tenant: organisation)
  end

  defp filter_by_action(query, :create), do: filter(query, create == true)
  defp filter_by_action(query, :destroy), do: filter(query, destroy == true)
  defp filter_by_action(query, :update), do: filter(query, update == true)

  defp get_resource_name(resource) do
    resource
    |> Module.split()
    |> List.last()
  end
end
