defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  resources do
    resource Omedis.Accounts.User
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.Tenant
  end
end
