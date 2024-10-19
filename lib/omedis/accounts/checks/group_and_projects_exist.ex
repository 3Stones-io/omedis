defmodule Omedis.Accounts.Checks.GroupAndProjectExist do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_) do
    "group and project must exist"
  end

  @impl true
  def match?(_actor, context, _opts) do
    tenant = Ash.load!(context.subject.tenant, [:groups, :projects])

    groups_exist = length(tenant.groups) > 0
    projects_exist = length(tenant.projects) > 0

    groups_exist and projects_exist
  end
end
