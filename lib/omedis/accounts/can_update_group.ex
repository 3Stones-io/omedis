defmodule Omedis.Accounts.CanUpdateGroup do
  @moduledoc false

  use Ash.Policy.SimpleCheck

  require Ash.Query

  def describe(_options) do
    "User can update group if they are the owner or have write access through a group."
  end

  def match?(actor, context, _opts) do
    tenant = context.subject.tenant

    cond do
      is_nil(actor) ->
        false

      is_nil(tenant) ->
        false

      true ->
        check_access_rights(tenant.id) and
          check_group_user(actor.id)
    end
  end

  defp check_access_rights(tenant_id) do
    Omedis.Accounts.AccessRight
    |> Ash.Query.filter(tenant_id == ^tenant_id && (write || update))
    |> Ash.exists?()
  end

  defp check_group_user(actor_id) do
    Omedis.Accounts.GroupUser
    |> Ash.Query.filter(user_id == ^actor_id)
    |> Ash.exists?()
  end
end
