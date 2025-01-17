defmodule Omedis.Accounts.User.Changes.AddInvitedUserToInvitationGroups do
  @moduledoc """
  Adds a user to the groups they were invited to when the invitation was being created.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts
  alias Omedis.Groups
  alias Omedis.Invitations

  @impl true
  def change(
        %{context: %{invitation_id: invitation_id}} = changeset,
        _opts,
        _context
      )
      when not is_nil(invitation_id) do
    Ash.Changeset.after_action(changeset, fn
      _changeset, user ->
        {:ok, invitation} = Invitations.get_invitation_by_id(invitation_id, authorize?: false)

        {:ok, current_organisation} =
          Accounts.get_organisation_by_id(invitation.organisation_id, authorize?: false)

        add_user_to_invited_groups(user, invitation, current_organisation)

        {:ok, user}
    end)
  end

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

        add_user_to_organisation_groups(user, current_organisation)

        {:ok, user}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp add_user_to_invited_groups(user, invitation, current_organisation) do
    {:ok, invitation_groups} = get_invitation_groups(invitation.id, current_organisation)

    Enum.each(invitation_groups, fn group ->
      {:ok, _} =
        Groups.create_group_membership(
          %{
            group_id: group.group_id,
            user_id: user.id
          },
          authorize?: false,
          tenant: current_organisation
        )
    end)
  end

  defp add_user_to_organisation_groups(user, current_organisation) do
    {:ok, organisation_groups} = get_organisation_groups(current_organisation)

    Enum.each(organisation_groups, fn group ->
      {:ok, _} =
        Groups.create_group_membership(
          %{
            group_id: group.group_id,
            user_id: user.id
          },
          authorize?: false,
          tenant: current_organisation
        )
    end)
  end

  defp get_invitation_groups(invitation_id, current_organisation) do
    Invitations.InvitationGroup
    |> Ash.Query.filter(invitation_id: invitation_id, organisation_id: current_organisation.id)
    |> Ash.read(authorize?: false, tenant: current_organisation)
  end

  defp get_organisation_groups(current_organisation) do
    Invitations.InvitationGroup
    |> Ash.Query.filter(organisation_id: current_organisation.id)
    |> Ash.read(authorize?: false, tenant: current_organisation)
  end
end
