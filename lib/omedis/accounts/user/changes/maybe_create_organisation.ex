defmodule Omedis.Accounts.User.Changes.MaybeCreateOrganisation do
  @moduledoc false

  use Ash.Resource.Change

  alias Omedis.Accounts
  alias Omedis.Invitations.Invitation

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, user ->
      if invitee?(user.email) do
        user
      else
        user
        |> create_organisation()
        |> update_user_current_organisation(user)
      end

      {:ok, user}
    end)
  end

  defp invitee?(email) do
    Invitation
    |> Ash.Query.filter(email: email)
    |> Ash.read_one!(authorize?: false)
  end

  defp create_organisation(user) do
    Accounts.create_organisation!(
      %{
        name: user.email,
        owner_id: user.id
      },
      actor: user,
      authorize?: false,
      upsert?: true,
      upsert_identity: :unique_slug
    )
  end

  defp update_user_current_organisation(organisation, user) do
    Accounts.update_user!(user, %{current_organisation_id: organisation.id})
  end
end
