defmodule Omedis.Accounts.User.Changes.AssociateUserWithInvitationOrganisation do
  @moduledoc """
  Associates a newly registered user with their invitation organisation
  by updating the user's `current_organisation_id` field after the user is created.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Accounts
  alias Omedis.Invitations

  def change(
        %{context: %{invitation_id: invitation_id}} = changeset,
        _opts,
        _context
      )
      when not is_nil(invitation_id) do
    Ash.Changeset.before_action(
      changeset,
      fn changeset -> maybe_update_user_current_organisation(changeset, invitation_id) end,
      prepend?: true
    )
  end

  def change(changeset, _opts, _context), do: changeset

  defp maybe_update_user_current_organisation(changeset, invitation_id) do
    {:ok, invitation} = Invitations.get_invitation_by_id(invitation_id, authorize?: false)

    {:ok, organisation} =
      Accounts.get_organisation_by_id(invitation.organisation_id, authorize?: false)

    Ash.Changeset.force_change_attributes(changeset, %{
      current_organisation_id: organisation.id,
      daily_start_at: organisation.default_daily_start_at,
      daily_end_at: organisation.default_daily_end_at
    })
  end
end
