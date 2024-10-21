defmodule OmedisWeb.TenantLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Tenant

  describe "/tenants" do
    setup do
      # Create users
      {:ok, user_1} = create_user()
      {:ok, user_2} = create_user()

      # Create groups
      {:ok, group_1} = create_group()
      {:ok, group_2} = create_group()

      # Associate users with groups
      {:ok, _} = create_group_user(%{group_id: group_1.id, user_id: user_1.id})
      {:ok, _} = create_group_user(%{group_id: group_2.id, user_id: user_2.id})

      # Create tenants (15 for user_1, 5 for user_2)
      tenants =
        for i <- 1..20 do
          {:ok, tenant} =
            create_tenant(%{
              name: "Tenant #{String.pad_leading("#{i}", 2, "0")}",
              slug: "tenant-#{i}"
            })

          tenant
        end

      # Set up access rights for user_1 (15 tenants)
      Enum.each(1..15, fn i ->
        {:ok, _} =
          create_access_right(%{
            group_id: group_1.id,
            tenant_id: Enum.at(tenants, i - 1).id,
            read: true,
            resource_name: "Tenant"
          })
      end)

      # Set up access rights for user_2 (5 tenants)
      Enum.each(16..20, fn i ->
        {:ok, _} =
          create_access_right(%{
            group_id: group_2.id,
            tenant_id: Enum.at(tenants, i - 1).id,
            read: true,
            resource_name: "Tenant"
          })
      end)

      %{user_1: user_1, user_2: user_2, tenants: tenants}
    end

    test "lists all tenants with pagination", %{conn: conn, user_1: user_1} do
      {:ok, index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/tenants")

      assert html =~ "Listing Tenants"
      assert html =~ "Tenant 01"
      assert html =~ "Tenant 10"
      refute html =~ "Tenant 11"

      assert index_live |> element("#tenants") |> render() =~ "Tenant 01"

      # Test pagination
      assert index_live |> element("nav[aria-label=Pagination]") |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      refute html =~ "Tenant 01"
      refute html =~ "Tenant 10"
      assert html =~ "Tenant 11"
      assert html =~ "Tenant 15"
      refute html =~ "Tenant 16"
    end

    test "filters tenants based on user access rights", %{
      conn: conn,
      user_1: user_1,
      user_2: user_2
    } do
      # Test for user_1
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/tenants")

      assert html =~ "Tenant 01"
      assert html =~ "Tenant 10"
      refute html =~ "Tenant 16"

      # Test for user_2
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/tenants")

      refute html =~ "Tenant 01"
      refute html =~ "Tenant 15"
      assert html =~ "Tenant 16"
      assert html =~ "Tenant 20"
    end

    test "shows tenants owned by the user", %{conn: conn, user_2: user_2, tenants: tenants} do
      # Assign ownership of a tenant to user_1
      # This tenant is not in user_1's access rights
      owned_tenant = Enum.at(tenants, 0)
      {:ok, _} = Tenant.update(owned_tenant, %{owner_id: user_2.id})

      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/tenants")

      assert html =~ owned_tenant.name
    end

    test "shows tenants count", %{conn: conn, tenants: tenants, user_1: user_1} do
      owned_tenant = Enum.at(tenants, 15)
      {:ok, _} = Tenant.update(owned_tenant, %{owner_id: user_1.id})

      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/tenants")

      assert html =~ "Tenants (16)"
    end
  end
end
