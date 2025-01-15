defmodule Omedis.Accounts.User.Changes.AssociateUserWithInvitationOrganisation do
  @moduledoc """
  Associates a newly registered user with their invitation organisation
  by updating the user's `current_organisation_id` field after the user is created.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Accounts
  alias Omedis.Invitations

  def change(%{attributes: %{email: email}} = changeset, _opts, _context) do
    Ash.Changeset.after_transaction(changeset, fn
      _changeset, {:ok, user} ->
        user = maybe_update_current_organisation(email, user)

        {:ok, user}

      _changeset, {:error, error} ->
        {:error, error}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp maybe_update_current_organisation(email, user) do
    case get_invitation(email) do
      {:ok, invitation} ->
        Accounts.update_user!(user, %{current_organisation_id: invitation.organisation_id},
          authorize?: false
        )

      _ ->
        user
    end
  end

  defp get_invitation(email) do
    Invitations.Invitation
    |> Ash.Query.filter(email: email)
    |> Ash.Query.filter(expires_at > ^DateTime.utc_now())
    |> Ash.read(authorize?: false)
  end
end
