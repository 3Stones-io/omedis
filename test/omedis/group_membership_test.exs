defmodule Omedis.GroupMembershipTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.GroupMembership

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, user} = create_user()
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "GroupMembership",
        tenant_id: tenant.id,
        write: true
      })

    {:ok,
     %{authorized_user: authorized_user, group: group, owner: owner, tenant: tenant, user: user}}
  end

  describe "create/1" do
    test "tenant owner can create a group_membership", %{
      group: group,
      owner: owner,
      tenant: tenant,
      user: user
    } do
      assert {:ok, group_membership} =
               GroupMembership.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: owner,
                 tenant: tenant
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "authorized user can create a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      assert {:ok, group_membership} =
               GroupMembership.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: authorized_user,
                 tenant: tenant
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "unauthorized user cannot create a group_membership", %{
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupMembership.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: unauthorized_user,
                 tenant: tenant
               )
    end
  end

  describe "read/0" do
    test "tenant owner can read all group_memberships", %{
      group: group,
      owner: owner,
      tenant: tenant,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, group_memberships} = GroupMembership.read(actor: owner, tenant: tenant)
      assert length(group_memberships) > 0
    end

    test "authorized user can read all group_memberships", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: tenant
        )

      {:ok, group_memberships} = GroupMembership.read(actor: authorized_user, tenant: tenant)
      assert length(group_memberships) > 0
    end

    test "unauthorized user cannot read group_memberships", %{
      group: group,
      owner: owner,
      tenant: tenant,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, unauthorized_user} = create_user()
      assert {:ok, []} = GroupMembership.read(actor: unauthorized_user, tenant: tenant)
    end
  end

  describe "destroy/1" do
    test "tenant owner can delete a group_membership", %{
      group: group,
      owner: owner,
      tenant: tenant,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      assert :ok = GroupMembership.destroy(group_membership, actor: owner, tenant: tenant)

      {:ok, group_memberships} = GroupMembership.read(actor: owner, tenant: tenant)
      refute Enum.any?(group_memberships, fn gu -> gu.id == group_membership.id end)
    end

    test "authorized user can delete a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: tenant
        )

      assert :ok =
               GroupMembership.destroy(group_membership, actor: authorized_user, tenant: tenant)

      {:ok, group_memberships} = GroupMembership.read(actor: authorized_user, tenant: tenant)
      refute Enum.any?(group_memberships, fn gu -> gu.user_id == group_membership.user_id end)
    end

    test "unauthorized user cannot delete a group_membership", %{
      group: group,
      owner: owner,
      tenant: tenant,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupMembership.destroy(group_membership, actor: unauthorized_user, tenant: tenant)
    end
  end
end
