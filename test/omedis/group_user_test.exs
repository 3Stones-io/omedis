defmodule Omedis.GroupUserTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.GroupUser

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, user} = create_user()
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "GroupUser",
        tenant_id: tenant.id,
        write: true
      })

    {:ok,
     %{tenant: tenant, group: group, user: user, owner: owner, authorized_user: authorized_user}}
  end

  describe "create/1" do
    test "tenant owner can create a group_user", %{
      owner: owner,
      group: group,
      tenant: tenant,
      user: user
    } do
      assert {:ok, group_user} =
               GroupUser.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: owner,
                 tenant: tenant
               )

      assert group_user.group_id == group.id
      assert group_user.user_id == user.id
    end

    test "authorized user can create a group_user", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      assert {:ok, group_user} =
               GroupUser.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: authorized_user,
                 tenant: tenant
               )

      assert group_user.group_id == group.id
      assert group_user.user_id == user.id
    end

    test "unauthorized user cannot create a group_user", %{
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupUser.create(
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
    test "tenant owner can read all group_users", %{
      owner: owner,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, group_users} = GroupUser.read(actor: owner, tenant: tenant)
      assert length(group_users) > 0
    end

    test "authorized user can read all group_users", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: tenant
        )

      {:ok, group_users} = GroupUser.read(actor: authorized_user, tenant: tenant)
      assert length(group_users) > 0
    end

    test "unauthorized user cannot read group_users", %{
      group: group,
      tenant: tenant,
      user: user,
      owner: owner
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, unauthorized_user} = create_user()
      assert {:error, _} = GroupUser.read(actor: unauthorized_user, tenant: tenant)
    end
  end

  describe "destroy/1" do
    test "tenant owner can delete a group_user", %{
      owner: owner,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      assert :ok = GroupUser.destroy(group_user, actor: owner, tenant: tenant)

      {:ok, group_users} = GroupUser.read(actor: owner, tenant: tenant)
      refute Enum.any?(group_users, fn gu -> gu.id == group_user.id end)
    end

    test "authorized user can delete a group_user", %{
      authorized_user: authorized_user,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: tenant
        )

      assert :ok = GroupUser.destroy(group_user, actor: authorized_user, tenant: tenant)

      {:ok, group_users} = GroupUser.read(actor: authorized_user, tenant: tenant)
      refute Enum.any?(group_users, fn gu -> gu.user_id == group_user.user_id end)
    end

    test "unauthorized user cannot delete a group_user", %{
      group: group,
      tenant: tenant,
      user: user,
      owner: owner
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: tenant
        )

      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupUser.destroy(group_user, actor: unauthorized_user, tenant: tenant)
    end
  end
end
