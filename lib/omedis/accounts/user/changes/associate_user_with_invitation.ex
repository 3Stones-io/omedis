defmodule Omedis.Accounts.User.Changes.AssociateUserWithInvitation do
  @moduledoc """
  Associates a newly registered user with their invitation
  by updating the invitation's `user_id` field after the user is created.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Invitations

  @impl true
  def change(
        %{context: %{invitation_id: invitation_id}} = changeset,
        _opts,
        _context
      )
      when not is_nil(invitation_id) do
    Ash.Changeset.after_transaction(changeset, fn
      _changeset, {:ok, user} ->
        maybe_update_invitation(invitation_id, user)
        {:ok, user}

      _changeset, {:error, error} ->
        {:error, error}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp maybe_update_invitation(invitation_id, user) do
    case Invitations.get_invitation_by_id(invitation_id, authorize?: false) do
      {:ok, invitation} ->
        Invitations.accept_invitation(invitation,
          actor: user,
          authorize?: false
        )

      _ ->
        :ok
    end
  end
end
