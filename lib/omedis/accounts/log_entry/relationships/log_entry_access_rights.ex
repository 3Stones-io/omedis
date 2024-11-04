defmodule Omedis.Accounts.LogEntry.Relationships.LogEntryAccessRights do
  @moduledoc """
  A relationship that allows us to access the log entry access rights for a log entry.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.Accounts.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("LogEntry", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "LogEntry",
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
      "LogEntry",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
