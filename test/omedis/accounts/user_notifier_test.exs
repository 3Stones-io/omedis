defmodule Omedis.Accounts.UserNotifierTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Swoosh.TestAssertions

  require Ash.Query

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: user.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})

    {:ok, invitation} =
      create_invitation(%{
        tenant_id: tenant.id,
        creator_id: user.id,
        groups: [group.id]
      })

    create_access_right(%{
      resource_name: "Invitation",
      create: true,
      tenant_id: tenant.id,
      group_id: group.id
    })

    create_access_right(%{
      resource_name: "Tenant",
      create: true,
      tenant_id: tenant.id,
      group_id: group.id
    })

    %{
      group: group,
      invitation: Ash.load!(invitation, :tenant, authorize?: false),
      tenant: tenant,
      user: user
    }
  end

  describe "deliver_invitation_email/2" do
    test "sends an invitation email",
         %{
           invitation: invitation,
           tenant: tenant
         } do
      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation to join #{tenant.name}",
        to: [invitation.email],
        text_body: ~r/INVITATION_URL/
      )
    end

    test "sends an invitation email in the correct language",
         %{
           group: group,
           tenant: tenant,
           user: user
         } do
      {:ok, invitation} =
        create_invitation(%{
          tenant_id: tenant.id,
          creator_id: user.id,
          groups: [group.id],
          language: "fr"
        })

      invitation = Ash.load!(invitation, :tenant, authorize?: false)

      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation à rejoindre #{tenant.name}",
        to: [invitation.email],
        text_body: ~r/INVITATION_URL/,
        text_body: ~r/Veuillez enregistrer votre nouveau compte Omedis pour/
      )
    end
  end
end
