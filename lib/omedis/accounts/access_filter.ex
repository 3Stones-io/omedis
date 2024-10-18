defmodule Omedis.Accounts.DebugAccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(actor, context, options) do
    tenant_id = context.subject.tenant.id

    resource_name =
      options[:resource]
      |> to_string()
      |> String.split(".")
      |> List.last()

    action_type = context.action.type

    expr(
      exists(
        Omedis.Accounts.AccessRight,
        tenant_id == ^tenant_id and
          resource_name == ^resource_name and
          ^action_type == true and
          exists(group.group_users, user_id == ^actor.id)
      )
    )
  end

  def requires_original_data?(_context, _options) do
    false
  end
end
