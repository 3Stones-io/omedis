defmodule OmedisWeb.TenantLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Tenant

  setup [:register_and_log_in_user]

  setup %{user: user} do
    {:ok, tenant} = create_tenant(%{name: "Test Tenant", slug: "test-tenant"})
    {:ok, group} = create_group()
    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: user.id})

    {:ok, tenant: tenant, group: group}
  end

  describe "/tenants/:slug" do
    test "shows tenant page when user has read access or is owner", %{
      conn: conn,
      group: group,
      tenant: tenant
    } do
      {:ok, _access_right} =
        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          resource_name: "Tenant"
        })

      {:ok, _show_live, html} = live(conn, ~p"/tenants/#{tenant}")

      assert html =~ tenant.name
    end

    test "doesn't show tenant page when user has no read access", %{conn: conn} do
      {:ok, tenant} = create_tenant()

      assert_raise Ash.Error.Query.NotFound, fn ->
        live(conn, ~p"/tenants/#{tenant}")
      end
    end

    test "shows tenant page for owner without access rights", %{conn: conn, user: user} do
      {:ok, owned_tenant} =
        create_tenant(%{name: "Owned Tenant", slug: "owned-tenant", owner_id: user.id})

      {:ok, _show_live, html} = live(conn, ~p"/tenants/#{owned_tenant}")

      assert html =~ owned_tenant.name
    end

    test "shows edit button when user has write or update access", %{
      conn: conn,
      group: group,
      tenant: tenant
    } do
      {:ok, access_right} =
        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          resource_name: "Tenant",
          update: false,
          write: false
        })

      {:ok, _show_live, html} = live(conn, ~p"/tenants/#{tenant}")
      refute html =~ "Edit tenant"

      Ash.update!(access_right, %{write: true, update: false})

      {:ok, _show_live, html} = live(conn, ~p"/tenants/#{tenant}")
      assert html =~ "Edit tenant"

      Ash.update!(access_right, %{write: false, update: true})

      {:ok, _show_live, html} = live(conn, ~p"/tenants/#{tenant}")
      assert html =~ "Edit tenant"
    end

    test "shows edit button for tenant owner without access rights", %{conn: conn, user: user} do
      {:ok, owned_tenant} =
        create_tenant(%{name: "Owned Tenant", slug: "owned-tenant", owner_id: user.id})

      {:ok, show_live, html} = live(conn, ~p"/tenants/#{owned_tenant}")

      assert html =~ "Edit tenant"

      assert show_live |> element("a", "Edit tenant") |> render_click() =~
               "Edit Tenant"

      assert_patch(show_live, ~p"/tenants/#{owned_tenant}/show/edit")

      assert show_live
             |> form("#tenant-form", tenant: %{street: ""})
             |> render_change() =~ "is required"

      attrs =
        Tenant
        |> attrs_for()
        |> Enum.reject(fn {_k, v} -> is_function(v) end)
        |> Enum.into(%{})
        |> Map.put(:name, "Updated Tenant")

      assert {:ok, _show_live, html} =
               show_live
               |> form("#tenant-form", tenant: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/tenants/#{attrs.slug}")

      assert html =~ "Tenant saved"
      assert html =~ "Updated Tenant"
    end
  end
end
