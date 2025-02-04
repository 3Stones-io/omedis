defmodule Omedis.Accounts.User.UserNotifier do
  @moduledoc false

  use Gettext, backend: OmedisWeb.Gettext

  import Swoosh.Email

  alias Omedis.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Omedis", "contact@omedis.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_reset_password_instructions(user, url) do
    Gettext.put_locale(user.lang)

    deliver(
      Ash.CiString.value(user.email),
      dgettext("emails", "Omedis | Reset your password"),
      dgettext(
        "emails",
        """
        ==============================

        Hello!

        Please click on this link %{url} to reset your password

        Best regards,

        Omedis.

        ==============================
        """,
        url: url
      )
    )
  end
end
