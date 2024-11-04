defmodule Omedis.Accounts.LogCategory.Relationships.LogCategoryAccessRights do
  @moduledoc """
  A relationship that allows us to access the LogCategory access rights for a LogCategory.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.Accounts.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("LogCategory", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "LogCategory",
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
      "LogCategory",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
