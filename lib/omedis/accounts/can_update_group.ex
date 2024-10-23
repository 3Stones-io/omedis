defmodule Omedis.Accounts.CanUpdateGroup do
  @moduledoc false

  use Ash.Policy.SimpleCheck

  require Ash.Query

  def describe(_options) do
    "User can update group if they are the owner or have write access through a group."
  end

  def match?(actor, context, _opts) do
    tenant = context.subject.tenant
    group_id = context.changeset.data.id

    cond do
      is_nil(actor) ->
        false

      is_nil(tenant) ->
        false

      true ->
        check_access_rights(tenant.id, group_id) and
          check_group_user(actor.id, group_id)
    end
  end

  defp check_access_rights(tenant_id, group_id) do
    Omedis.Accounts.AccessRight
    |> Ash.Query.filter(tenant_id == ^tenant_id && group_id == ^group_id && (write || update))
    |> Ash.exists?()
  end

  defp check_group_user(actor_id, group_id) do
    Omedis.Accounts.GroupUser
    |> Ash.Query.filter(user_id == ^actor_id && group_id == ^group_id)
    |> Ash.exists?()
  end
end
