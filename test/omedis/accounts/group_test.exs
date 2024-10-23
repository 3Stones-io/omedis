defmodule Omedis.Accounts.GroupTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.GroupUser

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: user.id})

    %{user: user, tenant: tenant}
  end

  describe "create/2" do
    test "Actor can create group if they are the tenant owner", %{user: user, tenant: tenant} do
      assert %Group{} =
               group =
               Group.create!(
                 %{
                   name: "Test Group",
                   tenant_id: tenant.id,
                   user_id: user.id,
                   slug: "test-group"
                 },
                 actor: user,
                 tenant: tenant
               )

      assert group.user_id == user.id
      assert group.tenant_id == tenant.id
    end

    test "Actor can't create group if they are not the tenant owner" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()

      assert_raise Ash.Error.Forbidden, fn ->
        Group.create!(
          %{name: "Test Group", tenant_id: tenant.id, user_id: user.id, slug: "test-group"},
          actor: user,
          tenant: tenant
        )
      end
    end
  end

  describe "update/2" do
    test "can update a group", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      assert %Group{} =
               updated_group =
               Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: tenant)

      assert updated_group.name == "Updated Group"
    end

    test "can't update a group if the actor doesn't have write/update access", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: false,
        update: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: tenant)
      end
    end

    test "can't update a group if actor is not in group_user", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: tenant)
      end
    end
  end

  describe "destroy/2" do
    test "can delete a group", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      # Will leave a 'ghost' group_user record :: only checking that no forbidden error is raised
      assert {:error, _} =
               Group.destroy(group, actor: user, tenant: tenant)
    end

    test "can't delete a group if actor doesn't have write/update access", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})
      {:ok, group_user} = create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: false,
        update: false
      })

      GroupUser.destroy(group_user, actor: user, tenant: tenant)

      assert_raise Ash.Error.Forbidden, fn ->
        Group.destroy!(group, actor: user, tenant: tenant)
      end
    end

    test "can't delete a group if actor is not in group_user", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.destroy!(group, actor: user, tenant: tenant)
      end
    end
  end

  describe "by_id!/1" do
    test "returns a group given a valid id and actor has read access", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true
      })

      assert %Group{} = result = Group.by_id!(group.id, actor: user, tenant: tenant)
      assert result.id == group.id
    end

    test "returns an error when an invalid group id is given", %{user: user, tenant: tenant} do
      invalid_id = Ecto.UUID.generate()

      create_group_user(%{user_id: user.id, group_id: invalid_id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: invalid_id,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(invalid_id, actor: user, tenant: tenant)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(group.id, actor: user, tenant: tenant)
      end
    end

    test "returns an error if group_user doesn't exist", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(group.id, actor: user, tenant: tenant)
      end
    end
  end

  describe "by_tenant_id/1" do
    test "returns paginated groups the user and tenant have access to", %{
      user: user,
      tenant: tenant
    } do
      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-#{i}"})

        create_group_user(%{user_id: user.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant.id,
          group_id: group.id,
          read: true
        })
      end)

      assert %Ash.Page.Offset{results: groups} =
               Group.by_tenant_id!(%{tenant_id: tenant.id},
                 actor: user,
                 tenant: tenant,
                 page: [limit: 10, offset: 0]
               )

      assert length(groups) == 10
    end

    test "returns an empty list when actor doesn't have read access", %{
      user: user,
      tenant: tenant
    } do
      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-#{i}"})

        create_group_user(%{user_id: user.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant.id,
          group_id: group.id,
          read: false
        })
      end)

      assert %Ash.Page.Offset{results: []} =
               Group.by_tenant_id!(%{tenant_id: tenant.id}, actor: user, tenant: tenant)
    end

    test "returns an empty list if no group_users exist for the groups", %{
      user: user,
      tenant: tenant
    } do
      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-#{i}"})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant.id,
          group_id: group.id,
          read: true
        })
      end)

      assert %Ash.Page.Offset{results: []} =
               Group.by_tenant_id!(%{tenant_id: tenant.id}, actor: user, tenant: tenant)
    end
  end

  describe "by_slug!/1" do
    test "returns a group given a valid slug and actor has read access", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-slug"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true
      })

      assert %Group{} = result = Group.by_slug!("test-group-slug", actor: user, tenant: tenant)
      assert result.id == group.id
    end

    test "returns an error when an invalid slug is given", %{user: user, tenant: tenant} do
      invalid_slug = "invalid-slug"

      create_group_user(%{user_id: user.id, group_id: invalid_slug})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: invalid_slug,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(invalid_slug, actor: user, tenant: tenant)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user, tenant: tenant} do
      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-slug"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(group.slug, actor: user, tenant: tenant)
      end
    end

    test "returns an error if group_user doesn't exist", %{user: user, tenant: tenant} do
      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: user.id, slug: "test-group-slug"})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(group.slug, actor: user, tenant: tenant)
      end
    end
  end
end
