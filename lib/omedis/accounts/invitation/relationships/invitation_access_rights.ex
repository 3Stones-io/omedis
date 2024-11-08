defmodule Omedis.Accounts.Invitation.Relationships.InvitationAccessRights do
  @moduledoc """
  A relationship that allows us to access the invitation access rights for an invitation.
  """

  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  alias Omedis.Accounts.Relationships.ResourceAccessRights

  def load(resources, opts, context) do
    ResourceAccessRights.load("Invitation", resources, opts, context)
  end

  def ash_postgres_join(query, opts, current_binding, as_binding, type, destination_query) do
    ResourceAccessRights.ash_postgres_join(
      "Invitation",
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
      "Invitation",
      opts,
      current_binding,
      as_binding,
      destination_query
    )
  end
end
