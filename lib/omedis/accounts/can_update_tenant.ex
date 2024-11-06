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

  def match?(nil, _context, _opts), do: false
  def match?(_actor, %{subject: %{data: nil}}, _opts), do: false

  def match?(actor, %{subject: %{data: tenant}}, _opts) when actor.id == tenant.owner_id,
    do: true

  def match?(actor, %{subject: %{data: tenant}}, _opts) do
    Ash.exists?(
      filter(
        AccessRight,
        tenant_id == ^tenant.id && (write || update) &&
          exists(group.group_memberships, user_id == ^actor.id)
      )
    )
  end
end
