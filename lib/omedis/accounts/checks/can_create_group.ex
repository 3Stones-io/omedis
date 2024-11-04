defmodule Omedis.Accounts.CanCreateGroup do
  @moduledoc false

  use Ash.Policy.SimpleCheck

  require Ash.Query

  def describe(_options) do
    "User can create group if they are the tenant owner."
  end

  def match?(nil, _context, _opts), do: false
  def match?(_actor, %{subject: %{tenant: nil}}, _opts), do: false
  def match?(actor, %{subject: %{tenant: tenant}}, _opts), do: tenant.owner_id == actor.id
end
