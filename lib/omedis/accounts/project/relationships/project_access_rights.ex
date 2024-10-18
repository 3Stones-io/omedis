defmodule Omedis.Accounts.Project.Relationships.ProjectAccessRights do
  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  require Ash.Query
  require Ecto.Query

  def load(_projects, _opts, %{query: query, actor: actor, authorize?: authorize?}) do
    {:ok,
     query
     |> Ash.Query.filter(resource_name == "Project")
     |> Ash.read!(actor: actor, authorize?: authorize?)
     |> Enum.group_by(& &1.tenant_id)}
  end

  def ash_postgres_join(query, _opts, _current_binding, as_binding, :inner, destination_query) do
    {:ok,
     Ecto.Query.from(q in query,
       join: ar in ^destination_query,
       as: ^as_binding,
       on: ar.resource_name == "Project"
     )}
  end

  def ash_postgres_join(query, _opts, _current_binding, as_binding, :left, destination_query) do
    {:ok,
     Ecto.Query.from(q in query,
       left_join: ar in ^destination_query,
       as: ^as_binding,
       on: ar.resource_name == "Project"
     )}
  end

  def ash_postgres_subquery(_opts, _current_binding, as_binding, destination_query) do
    {:ok,
     Ecto.Query.from(q in destination_query,
       where: field(as(^as_binding), :resource_name) == "Project"
     )}
  end
end
