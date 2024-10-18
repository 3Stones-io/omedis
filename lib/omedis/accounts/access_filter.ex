defmodule Omedis.Accounts.AccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  alias Omedis.Accounts.Tenant

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(actor, context, _options) do
    tenant =
      case context.query.tenant do
        %Tenant{} = tenant ->
          tenant

        tenant_id when is_binary(tenant_id) ->
          tenant_id = String.replace(context.query.tenant, "tenant_", "")
          Ash.get(Tenant, tenant_id)

        _ ->
          nil
      end

    case tenant do
      nil ->
        expr(false)

      tenant ->
        expr(
          exists(
            access_rights,
            tenant_id == ^tenant.id and
              read == true and
              exists(group.group_users, user_id == ^actor.id)
          ) and exists(tenant, id == ^tenant.id)
        )
    end
  end

  def requires_original_data?(_a, _b) do
    false
  end
end
