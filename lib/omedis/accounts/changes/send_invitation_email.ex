defmodule Omedis.Accounts.Changes.SendInvitationEmail do
  @moduledoc false
  use Ash.Resource.Change
  use OmedisWeb, :verified_routes

  alias Omedis.Accounts.UserNotifier

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_transaction(changeset, fn
      _changeset, {:ok, invitation} ->
        invitation =
          Ash.load!(invitation, :organisation, authorize?: false)

        url =
          static_url(
            OmedisWeb.Endpoint,
            ~p"/organisations/#{invitation.organisation}/invitations/#{invitation}"
          )

        case UserNotifier.deliver_invitation_email(invitation, url) do
          {:ok, _email} ->
            {:ok, invitation}

          {:error, error} ->
            Ash.Changeset.add_error(changeset, error)
        end

      _changeset, {:error, error} ->
        {:error, error}
    end)
  end
end
