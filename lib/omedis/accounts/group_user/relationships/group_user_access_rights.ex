defmodule Omedis.Accounts.GroupUser.Relationships.GroupUserAccessRights do
  @moduledoc """
  A relationship that allows us to access the group user access rights for a group user.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.Accounts.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("GroupUser", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "GroupUser",
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
      "GroupUser",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
