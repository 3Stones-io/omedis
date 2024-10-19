defmodule Omedis.Accounts.Checks.GroupAndProjectExist do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_) do
    "group and project must exist"
  end

  @impl true
  def match?(_actor, context, _opts) do
    tenant = context.subject.tenant

    group_exists? =
      Ash.exists?(Ash.Query.filter(Omedis.Accounts.Group, tenant_id == ^tenant.id))

    project_exists? =
      Ash.exists?(Ash.Query.filter(Omedis.Accounts.Project, tenant_id == ^tenant.id))

    group_exists? and project_exists?
  end
end
