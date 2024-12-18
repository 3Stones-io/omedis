defmodule Omedis.Groups.GroupMembershipTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Groups.GroupMembership

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, user} = create_user()
    {:ok, authorized_user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "GroupMembership",
        destroy: true,
        create: true
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
    test "organisation owner can create a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_membership} =
               GroupMembership.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: owner,
                 tenant: organisation
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "authorized user can create a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_membership} =
               GroupMembership.create(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: authorized_user,
                 tenant: organisation
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "unauthorized user cannot create a group_membership", %{
      group: group,
      organisation: organisation,
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
                 tenant: organisation
               )
    end
  end

  describe "read/0" do
    test "organisation owner can read all group_memberships", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, group_memberships} = GroupMembership.read(actor: owner, tenant: organisation)
      assert length(group_memberships) > 0
    end

    test "authorized user can read all group_memberships", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      {:ok, group_memberships} =
        GroupMembership.read(actor: authorized_user, tenant: organisation)

      assert length(group_memberships) > 0
    end

    test "unauthorized user cannot read group_memberships", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()
      assert {:ok, []} = GroupMembership.read(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "destroy/1" do
    test "organisation owner can delete a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      assert :ok = GroupMembership.destroy(group_membership, actor: owner, tenant: organisation)

      {:ok, group_memberships} = GroupMembership.read(actor: owner, tenant: organisation)
      refute Enum.any?(group_memberships, fn gm -> gm.id == group_membership.id end)
    end

    test "authorized user can delete a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      assert :ok =
               GroupMembership.destroy(group_membership,
                 actor: authorized_user,
                 tenant: organisation
               )

      {:ok, group_memberships} =
        GroupMembership.read(actor: authorized_user, tenant: organisation)

      refute Enum.any?(group_memberships, fn gm -> gm.user_id == group_membership.user_id end)
    end

    test "unauthorized user cannot delete a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        GroupMembership.create(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               GroupMembership.destroy(group_membership,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
