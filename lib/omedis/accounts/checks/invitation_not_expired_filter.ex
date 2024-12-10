defmodule Omedis.Accounts.InvitationNotExpiredFilter do
  @moduledoc """
  A policy that checks if an invitation has not expired.
  """

  use Ash.Policy.FilterCheck

  def describe(_options) do
    "Check whether the invitation has not expired"
  end

  def filter(_actor, _context, _options) do
    expr(status != ^:expired)
  end
end
