defmodule Omedis.Accounts.Activity.Relationships.ActivityAccessRights do
  @moduledoc """
  A relationship that allows us to access the access rights for an Activity.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.AccessRights.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("Activity", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "Activity",
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
      "Activity",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
