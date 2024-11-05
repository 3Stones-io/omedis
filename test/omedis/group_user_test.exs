defmodule Omedis.GroupUserTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.GroupUser

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, user} = create_user()
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "GroupUser",
        organisation_id: organisation.id,
        write: true
      })

    {:ok,
     %{
       authorized_user: authorized_user,
       group: group,
       owner: owner,
       organisation: organisation,
       user: user
     }}
  end

  describe "create/1" do
    test "organisation owner can create a group_user", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_user} =
               GroupUser.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: owner,
                 tenant: organisation
               )

      assert group_user.group_id == group.id
      assert group_user.user_id == user.id
    end

    test "authorized user can create a group_user", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_user} =
               GroupUser.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: authorized_user,
                 tenant: organisation
               )

      assert group_user.group_id == group.id
      assert group_user.user_id == user.id
    end

    test "unauthorized user cannot create a group_user", %{
      group: group,
      organisation: organisation,
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
                 tenant: organisation
               )
    end
  end

  describe "read/0" do
    test "organisation owner can read all group_users", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, group_users} = GroupUser.read(actor: owner, tenant: organisation)
      assert length(group_users) > 0
    end

    test "authorized user can read all group_users", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      {:ok, group_users} = GroupUser.read(actor: authorized_user, tenant: organisation)
      assert length(group_users) > 0
    end

    test "unauthorized user cannot read group_users", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()
      assert {:ok, []} = GroupUser.read(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "destroy/1" do
    test "organisation owner can delete a group_user", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      assert :ok = GroupUser.destroy(group_user, actor: owner, tenant: organisation)

      {:ok, group_users} = GroupUser.read(actor: owner, tenant: organisation)
      refute Enum.any?(group_users, fn gu -> gu.id == group_user.id end)
    end

    test "authorized user can delete a group_user", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      assert :ok = GroupUser.destroy(group_user, actor: authorized_user, tenant: organisation)

      {:ok, group_users} = GroupUser.read(actor: authorized_user, tenant: organisation)
      refute Enum.any?(group_users, fn gu -> gu.user_id == group_user.user_id end)
    end

    test "unauthorized user cannot delete a group_user", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_user} =
        GroupUser.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupUser.destroy(group_user, actor: unauthorized_user, tenant: organisation)
    end
  end
end
