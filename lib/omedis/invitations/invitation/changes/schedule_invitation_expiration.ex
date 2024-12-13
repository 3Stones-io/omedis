defmodule Omedis.Invitations.Invitation.Changes.ScheduleInvitationExpiration do
  @moduledoc """
  Schedules an Oban job to expire the invitation at the specified expiration time.
  """
  use Ash.Resource.Change

  alias Omedis.Invitations.Invitation.Workers.InvitationExpirationWorker

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, invitation ->
      {:ok, _oban_job} = schedule_expiration(invitation)

      {:ok, invitation}
    end)
  end

  defp schedule_expiration(invitation) do
    %{"invitation_id" => invitation.id}
    |> InvitationExpirationWorker.new(get_schedule_opts(invitation.expires_at))
    |> Oban.insert()
  end

  defp get_schedule_opts(expires_at) do
    now = DateTime.utc_now()

    if DateTime.compare(expires_at, now) == :gt do
      [scheduled_at: expires_at]
    else
      [schedule_in: 0]
    end
  end
end
