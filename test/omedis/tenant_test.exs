defmodule Omedis.TenantTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Tenant

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant()
    {:ok, group} = create_group()
    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: user.id})

    {:ok, user: user, tenant: tenant, group: group}
  end

  describe "read/0" do
    test "returns tenants the user has read access to or is owner", %{
      user: user,
      tenant: tenant,
      group: group
    } do
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      {:ok, tenants} = Tenant.read(actor: user)
      assert length(tenants) == 2
      assert Enum.any?(tenants, fn t -> t.id == tenant.id end)
      assert Enum.any?(tenants, fn t -> t.id == owned_tenant.id end)
    end

    test "returns only owned tenants when user has no read access", %{user: user} do
      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      {:ok, tenants} = Tenant.read(actor: user)
      assert length(tenants) == 1
      assert hd(tenants).id == owned_tenant.id
    end
  end

  describe "create/1" do
    test "is only allowed for users without a tenant", %{user: user} do
      assert {:error, _} = Tenant.create(%{name: "New Tenant", slug: "new-tenant"}, actor: user)

      {:ok, user_without_tenant} = create_user()

      assert {:ok, _} =
               Tenant
               |> attrs_for()
               |> Map.merge(%{
                 name: "New Tenant",
                 owner_id: user_without_tenant.id,
                 slug: "new-tenant"
               })
               |> Tenant.create(actor: user_without_tenant)
    end

    test "returns an error when attributes are invalid", %{user: user} do
      assert {:error, _} = Tenant.create(%{name: "Invalid Tenant"}, actor: user)
    end
  end

  describe "update/2" do
    test "requires write or update access", %{user: user, group: group} do
      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      assert {:ok, updated_tenant} = Tenant.update(owned_tenant, %{name: "Updated"}, actor: user)
      assert updated_tenant.name == "Updated"

      {:ok, tenant} = create_tenant()

      create_access_right(%{
        create: true,
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        read: true,
        update: false,
        write: false
      })

      assert {:error, _} = Tenant.update(tenant, %{name: "Updated"}, actor: user)

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        update: false,
        write: true
      })

      assert {:ok, updated_tenant} = Tenant.update(tenant, %{name: "Updated"}, actor: user)
      assert updated_tenant.name == "Updated"

      {:ok, tenant} = create_tenant()

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        update: true,
        write: false
      })

      assert {:ok, updated_tenant} = Tenant.update(tenant, %{name: "Updated"}, actor: user)
      assert updated_tenant.name == "Updated"
    end
  end

  describe "destroy/1" do
    test "requires ownership or write/update access", %{user: user, group: group} do
      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      assert :ok = Tenant.destroy(owned_tenant, actor: user)

      {:ok, tenant} = create_tenant()

      create_access_right(%{
        create: true,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        update: false,
        write: false
      })

      assert {:error, _} = Tenant.destroy(tenant, actor: user)

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        update: false,
        write: true
      })

      assert :ok = Tenant.destroy(tenant, actor: user)

      {:ok, tenant} = create_tenant()

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        update: true,
        write: false
      })

      assert :ok = Tenant.destroy(tenant, actor: user)
    end
  end

  describe "by_id/1" do
    test "returns a tenant given a valid id", %{user: user, tenant: tenant, group: group} do
      create_access_right(%{
        group_id: group.id,
        tenant_id: tenant.id,
        read: true,
        resource_name: "Tenant"
      })

      assert {:ok, fetched_tenant} = Tenant.by_id(tenant.id, actor: user)
      assert tenant.id == fetched_tenant.id
    end

    test "returns an error when user has no access", %{user: user, tenant: tenant} do
      assert {:error, _} = Tenant.by_id(tenant.id, actor: user)
    end

    test "returns a tenant for the owner without access rights", %{user: user} do
      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      assert {:ok, fetched_tenant} = Tenant.by_id(owned_tenant.id, actor: user)
      assert owned_tenant.id == fetched_tenant.id
    end
  end

  describe "by_slug/1" do
    test "returns a tenant given a slug", %{user: user, tenant: tenant, group: group} do
      create_access_right(%{
        group_id: group.id,
        tenant_id: tenant.id,
        read: true,
        resource_name: "Tenant"
      })

      assert {:ok, fetched_tenant} = Tenant.by_slug(tenant.slug, actor: user)
      assert tenant.slug == fetched_tenant.slug
    end

    test "returns an error when user has no access", %{user: user, tenant: tenant} do
      assert {:error, _} = Tenant.by_slug(tenant.slug, actor: user)
    end

    test "returns a tenant for the owner without access rights", %{user: user} do
      {:ok, owned_tenant} = create_tenant(%{owner_id: user.id})

      assert {:ok, fetched_tenant} = Tenant.by_slug(owned_tenant.slug, actor: user)
      assert owned_tenant.slug == fetched_tenant.slug
    end
  end

  describe "by_owner_id/1" do
    test "returns a tenant for a specific user", %{user: user} do
      {:ok, tenant} = create_tenant(%{slug: "tenant-one", owner_id: user.id})

      assert {:ok, [fetched_tenant]} = Tenant.by_owner_id(%{owner_id: user.id}, actor: user)
      assert tenant.id == fetched_tenant.id
    end

    test "returns an empty list when user owns no tenants", %{user: user} do
      assert {:ok, []} = Tenant.by_owner_id(%{owner_id: user.id}, actor: user)
    end
  end

  describe "list_paginated/1" do
    test "returns paginated tenants the user has access to", %{user: user, group: group} do
      Enum.each(1..15, fn i ->
        {:ok, tenant} = create_tenant(%{name: "Tenant #{i}", slug: "tenant-#{i}"})

        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          resource_name: "Tenant"
        })
      end)

      assert {:ok, %{results: tenants, count: total_count}} =
               Tenant.list_paginated(actor: user, page: [limit: 10, offset: 0])

      assert length(tenants) == 10
      assert total_count == 15

      assert {:ok, %{results: next_page}} =
               Tenant.list_paginated(actor: user, page: [limit: 10, offset: 10])

      assert length(next_page) == 5
    end
  end
end
