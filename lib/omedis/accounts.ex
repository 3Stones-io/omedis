defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  resources do
    resource Omedis.Accounts.AccessRight
    resource Omedis.Accounts.User
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.Tenant
    resource Omedis.Accounts.Activity
    resource Omedis.Accounts.LogEntry
    resource Omedis.Accounts.Project
    resource Omedis.Accounts.Group
    resource Omedis.Accounts.GroupMembership
    resource Omedis.Accounts.Invitation
    resource Omedis.Accounts.InvitationGroup
  end
end
