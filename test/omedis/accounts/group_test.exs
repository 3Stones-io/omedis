defmodule Omedis.Accounts.GroupTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Group

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: user.id})
    {:ok, authorized_user} = create_user()
    {:ok, group} = create_group(%{organisation_id: tenant.id})
    create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      organisation_id: tenant.id,
      write: true
    })

    %{user: user, tenant: tenant, authorized_user: authorized_user}
  end

  describe "create/2" do
    test "tenant owner can create a group", %{user: user, tenant: tenant} do
      assert %Group{} =
               group =
               Group.create!(
                 %{
                   name: "Test Group",
                   organisation_id: tenant.id,
                   user_id: user.id,
                   slug: "test-group"
                 },
                 actor: user,
                 tenant: tenant
               )

      assert group.user_id == user.id
      assert group.tenant_id == tenant.id
    end

    test "authorised users can create a group", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      assert %Group{} =
               group =
               Group.create!(
                 %{
                   name: "Test Group",
                   organisation_id: tenant.id,
                   user_id: authorized_user.id,
                   slug: "test-group"
                 },
                 actor: authorized_user,
                 tenant: tenant
               )

      assert group.user_id == authorized_user.id
      assert group.tenant_id == tenant.id
    end

    test "unauthorised users cannot create a group" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()

      assert_raise Ash.Error.Forbidden, fn ->
        Group.create!(
          %{name: "Test Group", organisation_id: tenant.id, user_id: user.id},
          actor: user,
          tenant: tenant
        )
      end
    end
  end

  describe "update/2" do
    test "can update a group if user is the owner of the tenant", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{organisation_id: tenant.id, user_id: user.id})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      assert %Group{} =
               updated_group =
               Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: tenant)

      assert updated_group.name == "Updated Group"
    end

    test "authorised users can create a group", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      {:ok, group} = create_group(%{organisation_id: tenant.id, user_id: authorized_user.id})

      assert %Group{} =
               updated_group =
               Group.update!(group, %{name: "New Name"}, actor: authorized_user, tenant: tenant)

      assert updated_group.name == "New Name"
    end

    test "unauthorized users cannot update group", %{
      user: user
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{organisation_id: tenant.id, user_id: user.id})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        write: false,
        update: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: tenant)
      end
    end
  end

  describe "destroy/2" do
    test "tenant owner can delete a group", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{organisation_id: tenant.id, user_id: user.id})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        write: true,
        update: true
      })

      assert :ok =
               Group.destroy(group, actor: user, tenant: tenant)
    end

    test "authorized users can delete a group", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      {:ok, group} = create_group(%{organisation_id: tenant.id, user_id: authorized_user.id})

      assert :ok =
               Group.destroy(group, actor: authorized_user, tenant: tenant)
    end

    test "can't delete a group if actor doesn't have write/update access", %{
      user: user
    } do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        write: false,
        update: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.destroy!(group, actor: user, tenant: tenant)
      end
    end
  end

  describe "by_id!/1" do
    test "returns a group given a valid id", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} =
        create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
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
        organisation_id: tenant.id,
        group_id: invalid_id,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(invalid_id, actor: user, tenant: tenant)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user} do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        read: false
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
          create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group-#{i}"})

        create_group_user(%{user_id: user.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          organisation_id: tenant.id,
          group_id: group.id,
          read: true
        })
      end)

      assert %Ash.Page.Offset{results: groups} =
               Group.by_tenant_id!(%{organisation_id: tenant.id},
                 actor: user,
                 tenant: tenant,
                 page: [limit: 10, offset: 0]
               )

      assert length(groups) == 10
    end

    test "returns an empty list when actor doesn't have read access", %{
      user: user
    } do
      {:ok, tenant} = create_tenant()

      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group-#{i}"})

        create_group_user(%{user_id: user.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          organisation_id: tenant.id,
          group_id: group.id,
          read: false
        })
      end)

      assert %Ash.Page.Offset{results: []} =
               Group.by_tenant_id!(%{organisation_id: tenant.id}, actor: user, tenant: tenant)
    end
  end

  describe "by_slug!/1" do
    test "returns a group given a valid slug and actor has read access", %{
      user: user,
      tenant: tenant
    } do
      {:ok, group} =
        create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group-slug"})

      {:ok, group2} =
        create_group(%{organisation_id: tenant.id, user_id: user.id})

      create_group_user(%{user_id: user.id, group_id: group2.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
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
        organisation_id: tenant.id,
        group_id: invalid_slug,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(invalid_slug, actor: user, tenant: tenant)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user} do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{organisation_id: tenant.id, user_id: user.id, slug: "test-group-slug"})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        organisation_id: tenant.id,
        group_id: group.id,
        read: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(group.slug, actor: user, tenant: tenant)
      end
    end
  end
end
