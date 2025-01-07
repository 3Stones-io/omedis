defmodule Omedis.Invitations do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Omedis.Invitations.Invitation do
      define :accept_invitation, action: :accept
      define :create_invitation, action: :create
      define :delete_invitation, action: :destroy
      define :get_invitation_by_id, get_by: [:id], action: :by_id
      define :list_paginated_invitations, action: :list_paginated
      define :mark_invitation_as_expired, action: :expire
    end

    resource Omedis.Invitations.InvitationGroup
  end

  defdelegate deliver_invitation_email(invitation, invitation_url),
    to: Omedis.Invitations.Invitation.InvitationNotifier
end
