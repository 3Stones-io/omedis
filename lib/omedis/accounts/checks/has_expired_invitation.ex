defmodule Omedis.Accounts.HasExpiredInvitation do
  @moduledoc """
  A policy that checks if an invitation has expired.
  """

  use Ash.Policy.FilterCheck

  def describe(_options) do
    "Check whether the invitation has expired"
  end

  def filter(_actor, _context, _options) do
    expr(expires_at > ^DateTime.utc_now())
  end
end
