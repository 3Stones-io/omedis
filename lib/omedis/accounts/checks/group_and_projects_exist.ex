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

    group_exists? =
      Ash.exists?(Ash.Query.filter(Omedis.Accounts.Group, organisation_id == ^organisation.id))

    project_exists? =
      Ash.exists?(Ash.Query.filter(Omedis.Accounts.Project, organisation_id == ^organisation.id))

    group_exists? and project_exists?
  end
end
