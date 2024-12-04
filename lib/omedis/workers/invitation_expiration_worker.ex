defmodule Omedis.Workers.InvitationExpirationWorker do
  @moduledoc false
  use Oban.Worker, queue: :invitation_expiration

  require Ash.Query

  alias Omedis.Accounts.Invitation

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"invitation_id" => invitation_id}}) do
    case get_invitation(invitation_id, authorize?: false) do
      {:ok, []} ->
        # If invitation doesn't exist, that's ok - it might have been deleted
        :ok

      {:ok, [invitation]} ->
        {:ok, invitation} = Invitation.expire(invitation, authorize?: false)


        :ok
    end
  end

  defp get_invitation(invitation_id, opts) do
    Invitation
    |> Ash.Query.filter(id: invitation_id, status: :pending)
    |> Ash.read(opts)
  end
end
