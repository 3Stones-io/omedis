defmodule Omedis.Invitations.Invitation.Validations.ValidateUserNotRegistered do
  @moduledoc """
  Validates that no user account exists with the email address being used for the invitation.

  This validation prevents sending invitations to email addresses that already have registered accounts.
  If a user is found with the given email, the invitation creation will be rejected.
  """
  use Ash.Resource.Validation

  alias Omedis.Accounts

  @impl true
  def validate(changeset, _opts, context) do
    email = Ash.Changeset.get_attribute(changeset, :email)

    case Accounts.get_user_by_email(email, actor: context.actor, tenant: context.tenant) do
      {:ok, _} ->
        {:error, field: :email, message: "An account with this email already exists"}

      _ ->
        :ok
    end
  end
end
