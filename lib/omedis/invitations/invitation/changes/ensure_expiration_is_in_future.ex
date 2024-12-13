defmodule Omedis.Invitations.Invitation.Changes.EnsureExpirationIsInFuture do
  @moduledoc """
  Ensures that the expiration time is in the future.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &ensure_expiration_is_in_future/1)
  end

  defp ensure_expiration_is_in_future(changeset) do
    expires_at = Ash.Changeset.get_attribute(changeset, :expires_at)

    if expires_at > DateTime.utc_now() do
      changeset
    else
      Ash.Changeset.add_error(changeset, [:expires_at, "expiration time must be in the future"])
    end
  end
end
