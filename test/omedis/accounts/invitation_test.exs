defmodule Omedis.Accounts.InvitationTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.InvitationGroup
  alias Omedis.Workers.InvitationEmailWorker

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})

    {:ok, authorized_user} = create_user()
    create_group_membership(%{user_id: authorized_user.id, group_id: group.id})

    create_access_right(%{
      resource_name: "Invitation",
      create: true,
      organisation_id: organisation.id,
      group_id: group.id,
      read: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Organisation",
      organisation_id: organisation.id,
      write: true,
      create: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      organisation_id: organisation.id,
      write: true,
      create: true
    })

    {:ok, unauthorized_user} = create_user()
    {:ok, group_2} = create_group()
    create_group_membership(%{user_id: unauthorized_user.id, group_id: group_2.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      organisation: organisation,
      unauthorized_user: unauthorized_user
    }
  end

  describe "create/1" do
    test "organisation owner can create invitation and queue a job to send an invitation email",
         %{
           group: group,
           owner: owner,
           organisation: organisation
         } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: owner.id,
        organisation_id: organisation.id,
        groups: [group.id]
      }

      assert {:ok, invitation} =
               Invitation.create(attrs, actor: owner, organisation: organisation)

      assert_enqueued(
        worker: InvitationEmailWorker,
        args: %{
          actor_id: owner.id,
          organisation_id: organisation.id,
          id: invitation.id
        },
        queue: :invitation
      )

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.organisation_id == organisation.id

      invitation_groups = Ash.read!(InvitationGroup, authorize?: false)
      group_ids = Enum.map(invitation_groups, & &1.group_id)
      assert group.id in group_ids
    end

    test "authorized user can create invitation and queue a job to send an invitation email", %{
      organisation: organisation,
      group: group,
      authorized_user: user
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        organisation_id: organisation.id,
        groups: [group.id]
      }

      assert {:ok, invitation} = Invitation.create(attrs, actor: user, tenant: organisation)

      assert_enqueued(
        worker: InvitationEmailWorker,
        args: %{actor_id: user.id, organisation_id: organisation.id, id: invitation.id},
        queue: :invitation
      )

      assert invitation.email == "test@example.com"

      invitation_groups = Ash.read!(InvitationGroup, authorize?: false)
      group_ids = Enum.map(invitation_groups, & &1.group_id)
      assert group.id in group_ids
    end

    test "unauthorized user cannot create invitation and cannot queue a job to send an invitation email",
         %{
           organisation: organisation,
           group: group,
           unauthorized_user: user
         } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        organisation_id: organisation.id,
        groups: [group.id]
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               Invitation.create(attrs, actor: user, tenant: organisation)

      refute_enqueued(worker: InvitationEmailWorker)
    end

    test "validates required attributes", %{
      organisation: organisation,
      owner: owner,
      group: group
    } do
      attrs = %{
        language: "en",
        creator_id: owner.id,
        organisation_id: organisation.id,
        groups: [group.id]
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Invitation.create(attrs, actor: owner, tenant: organisation)
    end
  end
end
