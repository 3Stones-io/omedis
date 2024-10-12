defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  resources do
    resource Omedis.Accounts.User
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.Tenant
    resource Omedis.Accounts.LogCategory
    resource Omedis.Accounts.LogEntry
    resource Omedis.Accounts.Project
    resource Omedis.Accounts.Group
    resource Omedis.Accounts.GroupUser
  end
end
