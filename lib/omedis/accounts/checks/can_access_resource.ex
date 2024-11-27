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

  def match?(
        actor,
        %{subject: %{tenant: organisation, resource: resource, action: %{type: :update}}} =
          _context,
        _options
      ) do
    resource_name = get_resource_name(resource)

    Ash.exists?(
      filter(
        AccessRight,
        resource_name == ^resource_name and
          update == true and
          exists(group.group_memberships, user_id == ^actor.id)
      ),
      tenant: organisation
    )
  end

  def match?(
        actor,
        %{subject: %{tenant: organisation, resource: resource, action: %{type: :create}}} =
          _context,
        _options
      ) do
    resource_name = get_resource_name(resource)

    Ash.exists?(
      filter(
        AccessRight,
        resource_name == ^resource_name and
          create == true and
          exists(group.group_memberships, user_id == ^actor.id)
      ),
      tenant: organisation
    )
  end

  def match?(
        actor,
        %{subject: %{tenant: organisation, resource: resource, action: %{type: :destroy}}} =
          _context,
        _options
      ) do
    resource_name = get_resource_name(resource)

    Ash.exists?(
      filter(
        AccessRight,
        resource_name == ^resource_name and
          destroy == true and
          exists(group.group_memberships, user_id == ^actor.id)
      ),
      tenant: organisation
    )
  end

  defp get_resource_name(resource) do
    resource
    |> Module.split()
    |> List.last()
  end
end
