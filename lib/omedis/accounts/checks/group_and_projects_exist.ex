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
    organisation = context.subject.tenant

    group_exists? = Ash.exists?(Omedis.Groups.Group, tenant: organisation)
    project_exists? = Ash.exists?(Omedis.Accounts.Project, tenant: organisation)

    group_exists? and project_exists?
  end
end
