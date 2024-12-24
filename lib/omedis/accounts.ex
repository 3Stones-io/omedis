defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  require Ash.Query

  resources do
    resource Omedis.Accounts.Organisation
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.User
  end

  def slug_exists?(resource, filters, opts \\ []) do
    resource
    |> Ash.Query.filter(^filters)
    |> Ash.read_one!(opts)
  end
end
