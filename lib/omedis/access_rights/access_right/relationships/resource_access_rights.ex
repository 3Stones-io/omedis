defmodule Omedis.AccessRights.AccessRight.Relationships.ResourceAccessRights do
  @moduledoc """
  A relationship that allows us to access the access rights for a resource.
  """

  require Ash.Query
  require Ecto.Query

  def load(resource_name, _resources, _opts, %{actor: actor, authorize?: authorize?, query: query}) do
    {:ok,
     query
     |> Ash.Query.filter(resource_name == ^resource_name)
     |> Ash.read!(actor: actor, authorize?: authorize?)
     |> Enum.group_by(& &1.organisation_id)}
  end

  def ash_postgres_join(
        resource_name,
        query,
        _opts,
        _current_binding,
        as_binding,
        :inner,
        destination_query
      ) do
    {:ok,
     Ecto.Query.from(q in query,
       join: ar in ^destination_query,
       as: ^as_binding,
       on: ar.resource_name == ^resource_name
     )}
  end

  def ash_postgres_join(
        resource_name,
        query,
        _opts,
        _current_binding,
        as_binding,
        :left,
        destination_query
      ) do
    {:ok,
     Ecto.Query.from(q in query,
       left_join: ar in ^destination_query,
       as: ^as_binding,
       on: ar.resource_name == ^resource_name
     )}
  end

  def ash_postgres_subquery(resource_name, _opts, _current_binding, as_binding, destination_query) do
    {:ok,
     Ecto.Query.from(q in destination_query,
       where: field(as(^as_binding), :resource_name) == ^resource_name
     )}
  end
end
