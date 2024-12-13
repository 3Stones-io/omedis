defmodule Omedis.Invitations do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Omedis.Invitations.Invitation
    resource Omedis.Invitations.InvitationGroup
  end

  defdelegate deliver_invitation_email(invitation, invitation_url),
    to: Omedis.Invitations.Invitation.InvitationNotifier
end
