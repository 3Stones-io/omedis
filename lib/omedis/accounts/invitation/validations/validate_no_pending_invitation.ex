defmodule Omedis.Accounts.Invitation.Validations.ValidateNoPendingInvitation do
  @moduledoc """
  Validates that no pending invitation exists for the email address being used for the invitation.

  This validation ensures that only one invitation is sent per email address at a time.
  If a pending invitation is found, the existing invitation will be deleted before creating a new one.
  """
  use Ash.Resource.Validation

  require Ash.Query

  alias Omedis.Accounts.Invitation

  @impl true
  def validate(changeset, _opts, context) do
    email = Ash.Changeset.get_attribute(changeset, :email)

    case get_pending_invitation(email, authorize?: false, tenant: context.tenant) do
      {:ok, []} ->
        :ok

      {:ok, [invitation]} ->
        # If we get here, remove the existing invitation and proceed with creating the new one
        :ok = Invitation.destroy(invitation, actor: context.actor, tenant: context.tenant)

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_pending_invitation(email, opts) do
    Invitation
    |> Ash.Query.filter(email: email, organisation_id: opts[:tenant].id)
    |> Ash.Query.filter(is_nil(user_id))
    |> Ash.Query.filter(expires_at > ^DateTime.utc_now())
    |> Ash.read(opts)
  end
end
