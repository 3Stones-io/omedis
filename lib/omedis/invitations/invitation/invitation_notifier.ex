defmodule Omedis.Invitations.Invitation.InvitationNotifier do
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
      dgettext("emails", "Omedis | Invitation to join %{organisation_name}",
        organisation_name: invitation.organisation.name
      ),
      dgettext(
        "emails",
        """
        ==============================

        Hello!

        Please register your new Omedis account for %{organisation_name}

        This invitation is good till %{expires_at}

        Please click on this link %{url} to create the account

        Best regards,

        Omedis.

        ==============================
        """,
        expires_at: invitation.expires_at,
        organisation_name: invitation.organisation.name,
        url: url
      )
    )
  end
end
