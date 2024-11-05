defmodule Omedis.Accounts.InvitationTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.InvitationGroup

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})

    {:ok, authorized_user} = create_user()
    create_group_user(%{user_id: authorized_user.id, group_id: group.id})

    create_access_right(%{
      resource_name: "Invitation",
      create: true,
      tenant_id: tenant.id,
      group_id: group.id
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Tenant",
      tenant_id: tenant.id,
      write: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      tenant_id: tenant.id,
      write: true
    })

    {:ok, unauthorized_user} = create_user()
    {:ok, group_2} = create_group()
    create_group_user(%{user_id: unauthorized_user.id, group_id: group_2.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      tenant: tenant,
      unauthorized_user: unauthorized_user
    }
  end

  describe "create/1" do
    test "tenant owner can create invitation", %{
      group: group,
      owner: owner,
      tenant: tenant
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: owner.id,
        tenant_id: tenant.id,
        groups: [group.id]
      }

      assert {:ok, invitation} = Invitation.create(attrs, actor: owner, tenant: tenant)
      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.tenant_id == tenant.id

      invitation_groups = Ash.read!(InvitationGroup, authorize?: false)
      group_ids = Enum.map(invitation_groups, & &1.group_id)
      assert group.id in group_ids
    end

    test "authorized user can create invitation", %{
      tenant: tenant,
      group: group,
      authorized_user: user
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        tenant_id: tenant.id,
        groups: [group.id]
      }

      assert {:ok, invitation} = Invitation.create(attrs, actor: user, tenant: tenant)
      assert invitation.email == "test@example.com"

      invitation_groups = Ash.read!(InvitationGroup, authorize?: false)
      group_ids = Enum.map(invitation_groups, & &1.group_id)
      assert group.id in group_ids
    end

    test "unauthorized user cannot create invitation", %{
      tenant: tenant,
      group: group,
      unauthorized_user: user
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        tenant_id: tenant.id,
        groups: [group.id]
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               Invitation.create(attrs, actor: user, tenant: tenant)
    end

    test "validates required attributes", %{tenant: tenant, owner: owner, group: group} do
      attrs = %{
        language: "en",
        creator_id: owner.id,
        tenant_id: tenant.id,
        groups: [group.id]
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Invitation.create(attrs, actor: owner, tenant: tenant)
    end
  end
end
