defmodule Omedis.Accounts.CanUpdateTenant do
  @moduledoc """
  Determines whether a user can update a tenant.
  User either needs to be the owner of the tenant or have write access to the tenant through a group.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.AccessRight

  def describe(_options) do
    "User can update tenant if they are the owner or have write access through a group."
  end

  def match?(actor, context, _opts) do
    tenant = context.subject.data

    cond do
      is_nil(actor) ->
        false

      is_nil(tenant) ->
        false

      tenant.owner_id == actor.id ->
        true

      true ->
        Ash.exists?(
          filter(
            AccessRight,
            tenant_id == ^tenant.id && (write || update) &&
              exists(group.group_users, user_id == ^actor.id)
          )
        )
    end
  end
end
