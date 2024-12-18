defmodule Omedis.Accounts.User.Changes.AssociateUserWithInvitation do
  @moduledoc """
  Associates a newly registered user with their invitation
  by updating the invitation's `user_id` field after the user is created.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Invitations.Invitation

  def change(%{attributes: %{email: email}} = changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn
      _changeset, user ->
        maybe_update_invitation(email, user)

        {:ok, user}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp maybe_update_invitation(email, user) do
    case get_invitation(email) do
      {:ok, invitation} ->
        %{status: :success} = Invitation.accept(invitation, actor: user, authorize?: false)

      _ ->
        :ok
    end
  end

  defp get_invitation(email) do
    Invitation
    |> Ash.Query.filter(email: email)
    |> Ash.Query.filter(expires_at > ^DateTime.utc_now())
    |> Ash.read(authorize?: false)
  end
end
