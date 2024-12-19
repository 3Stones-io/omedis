defmodule Omedis.Accounts.User.Changes.AssociateUserWithInvitation do
  @moduledoc """
  Associates a newly registered user with their invitation
  by updating the invitation's `user_id` field after the user is created.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Invitations.Invitation

  def change(%{attributes: %{email: email}} = changeset, _opts, _context) do
    Ash.Changeset.after_transaction(changeset, fn
      _changeset, {:ok, user} ->
        :ok = maybe_update_invitation(email, user)

        {:ok, user}

      _changeset, {:error, error} ->
        {:error, error}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp maybe_update_invitation(email, user) do
    case get_invitation(email) do
      {:ok, invitation} ->
        %{status: :success, notifications: notifications} =
          Invitation.accept(invitation,
            actor: user,
            authorize?: false,
            return_notifications?: true
          )

        Enum.each(notifications, &Ash.Notifier.notify/1)

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
