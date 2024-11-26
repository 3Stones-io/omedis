defmodule Omedis.Accounts.UserNotifier.Behaviour do
  @moduledoc false

  @callback deliver_invitation_email(invitation :: struct(), url :: String.t()) ::
              {:ok, Swoosh.Email.t()} | {:error, term()}
end
