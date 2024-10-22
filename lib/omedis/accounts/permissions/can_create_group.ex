defmodule Omedis.Accounts.Permissions.CanCreateGroup do
  @moduledoc false

  use Ash.Policy.SimpleCheck

  require Ash.Query

  def describe(_options) do
    "User can create group if they are the tenant owner."
  end

  def match?(actor, context, _opts) do
    tenant = context.subject.tenant

    cond do
      is_nil(actor) ->
        false

      is_nil(tenant) ->
        false

      true ->
        tenant.owner_id == actor.id
    end
  end
end
