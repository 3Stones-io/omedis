defmodule Omedis.Workers.InvitationEmailWorkerTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Swoosh.TestAssertions
  import Omedis.TestUtils

  alias Omedis.Workers.InvitationEmailWorker

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
      invitation: invitation,
      organisation: organisation,
      user: user
    }
  end

  describe "perform/1" do
    test "sends an invitation email", %{
      invitation: invitation,
      organisation: organisation,
      user: user
    } do
      args = %{actor_id: user.id, organisation_id: organisation.id, id: invitation.id}

      assert :ok =
               perform_job(
                 InvitationEmailWorker,
                 args
               )

      assert_email_sent(
        from: {"Omedis", "contact@omedis.com"},
        subject: "Omedis | Invitation to join #{organisation.name}",
        to: invitation.email,
        text_body: ~r/Please register your new Omedis account for /
      )
    end
  end
end
