defmodule Omedis.Accounts.InvitationTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.{Invitation, InvitationGroup}
  import Omedis.Fixtures

  describe "create/1" do
    setup do
      tenant = create_tenant!()
      group = create_group!(tenant_id: tenant.id)
      other_group = create_group!(tenant_id: tenant.id)

      owner = get_tenant_owner(tenant)

      regular_user = create_user!()
      create_group_user!(user_id: regular_user.id, group_id: group.id)

      unauthorized_user = create_user!()

      authorized_user = create_user!()
      create_group_user!(user_id: authorized_user.id, group_id: group.id)

      create_access_right!(
        resource_name: "Invitation",
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      )

      %{
        tenant: tenant,
        group: group,
        other_group: other_group,
        owner: owner,
        regular_user: regular_user,
        unauthorized_user: unauthorized_user,
        authorized_user: authorized_user
      }
    end

    test "tenant owner can create invitation", %{
      tenant: tenant,
      group: group,
      other_group: other_group,
      owner: owner
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: owner.id,
        tenant_id: tenant.id,
        group_ids: [group.id, other_group.id]
      }

      assert {:ok, invitation} = Invitation.create(attrs, actor: owner)
      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.tenant_id == tenant.id

      invitation_groups = Ash.read!(InvitationGroup, filter: [invitation_id: invitation.id])
      assert length(invitation_groups) == 2
      group_ids = Enum.map(invitation_groups, & &1.group_id)
      assert group.id in group_ids
      assert other_group.id in group_ids
    end

    test "authorized user can create invitation", %{
      tenant: tenant,
      group: group,
      other_group: other_group,
      authorized_user: user
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        tenant_id: tenant.id,
        group_ids: [group.id, other_group.id]
      }

      assert {:ok, invitation} = Invitation.create(attrs, actor: user)
      assert invitation.email == "test@example.com"

      invitation_groups = Ash.read!(InvitationGroup, filter: [invitation_id: invitation.id])
      assert length(invitation_groups) == 2
    end

    test "regular user cannot create invitation", %{
      tenant: tenant,
      group: group,
      regular_user: user
    } do
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: user.id,
        tenant_id: tenant.id,
        group_ids: [group.id]
      }

      assert {:error, %Ash.Error.Forbidden{}} = Invitation.create(attrs, actor: user)
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
        group_ids: [group.id]
      }

      assert {:error, %Ash.Error.Forbidden{}} = Invitation.create(attrs, actor: user)
    end

    test "validates required attributes", %{tenant: tenant, owner: owner, group: group} do
      # Missing email
      attrs = %{
        language: "en",
        creator_id: owner.id,
        tenant_id: tenant.id,
        group_ids: [group.id]
      }

      assert {:error, %Ash.Error.Invalid{}} = Invitation.create(attrs, actor: owner)

      # Missing language
      attrs = %{
        email: "test@example.com",
        creator_id: owner.id,
        tenant_id: tenant.id,
        group_ids: [group.id]
      }

      assert {:error, %Ash.Error.Invalid{}} = Invitation.create(attrs, actor: owner)

      # Missing group_ids
      attrs = %{
        email: "test@example.com",
        language: "en",
        creator_id: owner.id,
        tenant_id: tenant.id
      }

      assert {:error, %Ash.Error.Invalid{}} = Invitation.create(attrs, actor: owner)
    end
  end
end
