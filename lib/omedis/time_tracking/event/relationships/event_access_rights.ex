defmodule Omedis.TimeTracking.Event.Relationships.EventAccessRights do
  @moduledoc """
  A relationship that allows us to access the event access rights for an event.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.AccessRights.AccessRight.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("Event", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "Event",
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
      "Event",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
