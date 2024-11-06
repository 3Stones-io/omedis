defmodule Omedis.Workers.InvitationEmailWorkerTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Swoosh.TestAssertions

  alias Omedis.Workers.InvitationEmailWorker

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
      invitation: invitation,
      tenant: tenant,
      user: user
    }
  end

  describe "perform/1" do
    test "sends an invitation email", %{
      invitation: invitation,
      tenant: tenant,
      user: user
    } do
      args = %{actor_id: user.id, tenant_id: tenant.id, id: invitation.id}

      assert :ok =
               perform_job(
                 InvitationEmailWorker,
                 args
               )

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation to join #{tenant.name}",
        to: invitation.email,
        text_body: ~r/Please register your new Omedis account for /
      )
    end
  end
end
