defmodule Omedis.Accounts.DebugAccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  alias Omedis.Accounts.AccessRight
  alias Omedis.Accounts.Tenant

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(actor, context, options) do
    tenant_id =
      case context.query.tenant do
        %Tenant{id: tenant_id} ->
          tenant_id

        _ ->
          String.replace(context.query.tenant, "tenant_", "")
      end

    resource_name =
      options[:resource]
      |> to_string()
      |> String.split(".")
      |> List.last()

    expr(
      exists(
        ^AccessRight,
        tenant_id == ^tenant_id and
          resource_name == ^resource_name and
          read == true and
          exists(group.group_users, user_id == ^actor.id)
      )
    )
  end

  def requires_original_data?(_a, _b) do
    false
  end
end
