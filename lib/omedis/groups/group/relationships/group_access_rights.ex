defmodule Omedis.Groups.Group.Relationships.GroupAccessRights do
  @moduledoc """
  A relationship that allows us to access the group access rights for a group.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.AccessRights.AccessRight.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("Group", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "Group",
      query,
      opts,
      current_binding,
      as_binding,
      type,
      destination_query
    )
  end

  def ash_postgres_subquery(opts, current_binding, as_binding, destination_query) do
    ResourceAccessRights.ash_postgres_subquery(
      "Group",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
