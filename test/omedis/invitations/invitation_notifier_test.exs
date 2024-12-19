defmodule Omedis.Invitations.InvitationNotifierTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Swoosh.TestAssertions
  import Omedis.TestUtils

  require Ash.Query

  setup do
    {:ok, user} = create_user()
    organisation = fetch_users_organisation(user.id)
    {:ok, group} = create_group(organisation)

    {:ok, invitation} =
      create_invitation(organisation, %{
        creator_id: user.id,
        groups: [group.id]
      })

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "Invitation",
        create: true,
        group_id: group.id
      })

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "organisation",
        create: true,
        group_id: group.id
      })

    %{
      group: group,
      invitation: Ash.load!(invitation, :organisation, authorize?: false),
      organisation: organisation,
      user: user
    }
  end

  describe "deliver_invitation_email/2" do
    test "sends an invitation email",
         %{
           invitation: invitation,
           organisation: organisation
         } do
      Omedis.Invitations.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation to join #{organisation.name}",
        to: [Ash.CiString.value(invitation.email)],
        text_body: ~r/INVITATION_URL/
      )
    end

    test "sends an invitation email in the correct language",
         %{
           group: group,
           organisation: organisation,
           user: user
         } do
      {:ok, invitation} =
        create_invitation(organisation, %{
          creator_id: user.id,
          groups: [group.id],
          language: "fr"
        })

      invitation = Ash.load!(invitation, :organisation, authorize?: false)

      Omedis.Invitations.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation à rejoindre #{organisation.name}",
        to: [Ash.CiString.value(invitation.email)],
        text_body: ~r/INVITATION_URL/,
        text_body: ~r/Veuillez enregistrer votre nouveau compte Omedis pour/
      )
    end
  end
end
