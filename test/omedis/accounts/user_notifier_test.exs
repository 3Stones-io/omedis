defmodule Omedis.Accounts.UserNotifierTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Swoosh.TestAssertions

  require Ash.Query

  setup do
    {:ok, user} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: user.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})

    {:ok, invitation} =
      create_invitation(%{
        organisation_id: organisation.id,
        creator_id: user.id,
        groups: [group.id]
      })

    {:ok, _} =
      create_access_right(%{
        resource_name: "Invitation",
        create: true,
        organisation_id: organisation.id,
        group_id: group.id
      })

    {:ok, _} =
      create_access_right(%{
        resource_name: "organisation",
        create: true,
        organisation_id: organisation.id,
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
      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation to join #{organisation.name}",
        to: [invitation.email],
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
        create_invitation(%{
          organisation_id: organisation.id,
          creator_id: user.id,
          groups: [group.id],
          language: "fr"
        })

      invitation = Ash.load!(invitation, :organisation, authorize?: false)

      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation à rejoindre #{organisation.name}",
        to: [invitation.email],
        text_body: ~r/INVITATION_URL/,
        text_body: ~r/Veuillez enregistrer votre nouveau compte Omedis pour/
      )
    end
  end
end
