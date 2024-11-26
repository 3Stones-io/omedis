defmodule Omedis.Accounts.UserNotifier do
  @moduledoc false

  def deliver_invitation_email(invitation, url) do
    impl().deliver_invitation_email(invitation, url)
  end

  defp impl do
    Application.get_env(:omedis, :user_notifier, Omedis.Accounts.UserNotifier.Client)
  end
end
