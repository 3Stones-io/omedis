defmodule Omedis.Accounts.User.Notifiers.SendPasswordResetEmail do
  @moduledoc false

  use AshAuthentication.Sender
  use OmedisWeb, :verified_routes

  alias Omedis.Accounts.User.UserNotifier

  @impl AshAuthentication.Sender
  def send(user, token, _opts) do
    UserNotifier.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
