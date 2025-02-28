defmodule Omedis.Accounts.User.Changes.AddInvitedUserToInvitationGroups do
  @moduledoc """
  Adds a user to the groups they were invited to when the invitation was being created.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts
  alias Omedis.Groups
  alias Omedis.Invitations.Invitation
  alias Omedis.Invitations.InvitationGroup

  @impl true
  def change(
        %{attributes: %{current_organisation_id: current_organisation_id}} = changeset,
        _opts,
        _context
      )
      when not is_nil(current_organisation_id) do
    Ash.Changeset.after_action(changeset, fn
      _changeset, user ->
        {:ok, current_organisation} =
          Accounts.get_organisation_by_id(current_organisation_id, authorize?: false)

        add_user_to_invited_groups(user, current_organisation)

        {:ok, user}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp add_user_to_invited_groups(user, current_organisation) do
    with {:ok, [invitation]} <- get_user_invitation(user.email, current_organisation.id),
         {:ok, invitation_groups} <- get_invitation_groups(invitation.id, current_organisation) do
      Enum.each(invitation_groups, fn invitation_group ->
        {:ok, _} =
          Groups.create_group_membership(
            %{
              group_id: invitation_group.group_id,
              user_id: user.id
            },
            authorize?: false,
            tenant: current_organisation
          )
      end)
    end
  end

  defp get_user_invitation(user_email, current_organisation_id) do
    Invitation
    |> Ash.Query.filter(email: user_email, organisation_id: current_organisation_id)
    |> Ash.read(authorize?: false)
  end

  defp get_invitation_groups(invitation_id, current_organisation) do
    InvitationGroup
    |> Ash.Query.filter(invitation_id: invitation_id, organisation_id: current_organisation.id)
    |> Ash.read(authorize?: false, tenant: current_organisation)
  end
end
