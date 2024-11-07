defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  resources do
    resource Omedis.Accounts.AccessRight
    resource Omedis.Accounts.Activity
    resource Omedis.Accounts.Group
    resource Omedis.Accounts.GroupMembership
    resource Omedis.Accounts.Invitation
    resource Omedis.Accounts.InvitationGroup
    resource Omedis.Accounts.LogEntry
    resource Omedis.Accounts.Organisation
    resource Omedis.Accounts.Project
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.User
  end
end
