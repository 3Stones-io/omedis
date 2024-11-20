defmodule Omedis.Accounts.CanDeleteAccount do
  @moduledoc """
  A policy that checks if a user can delete their own account.
  """

  use Ash.Policy.SimpleCheck

  def describe(_options), do: "User can delete their own account"

  def match?(nil, _context, _options), do: false

  def match?(actor, %{subject: %{data: user}}, _options) do
    user.id == actor.id
  end
end
