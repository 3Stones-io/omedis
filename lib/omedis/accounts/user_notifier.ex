defmodule Omedis.Accounts.UserNotifier do
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

  def deliver_invitation_email(invitation, url) do
    Gettext.put_locale(invitation.language)

    deliver(
      invitation.email,
      dgettext("emails", "Omedis | Invitation to join %{tenant_name}",
        tenant_name: invitation.tenant.name
      ),
      """
      ==============================

      #{dgettext("emails", "Hello!")}

      #{dgettext("emails", "Please register your new Omedis account for %{tenant_name}", tenant_name: invitation.tenant.name)}

      #{dgettext("emails", "This invitation is good till %{expires_at}", expires_at: invitation.expires_at)}

      #{dgettext("emails", "Please click on this link %{url} to create the account", url: url)}

      #{dgettext("emails", "Best regards,")}

      Omedis.

      ==============================
      """
    )
  end
end
