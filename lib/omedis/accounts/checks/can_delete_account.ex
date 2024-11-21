defmodule Omedis.Accounts.CanDeleteAccount do
  @moduledoc """
  A policy that checks if a user can delete their own account.
  """

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Organisation

  def describe(_options), do: "User can delete their own account"

  def match?(nil, _context, _options), do: false

  def match?(actor, _context, _options) do
    Ash.exists?(filter(Organisation, owner_id == ^actor.id), authorize?: false)
  end
end
