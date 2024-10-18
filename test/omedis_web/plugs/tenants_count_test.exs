defmodule OmedisWeb.Plugs.TenantsCountTest do
  use OmedisWeb.ConnCase, async: true

  alias OmedisWeb.Plugs.TenantsCount

  describe "call/2" do
    test "when user is logged in assigns the tenants_count with the number of tenants user has access to",
         %{conn: conn} do
      %{conn: conn, user: user_1} = register_and_log_in_user(%{conn: conn})

      {:ok, user_2} = create_user()
      {:ok, user_3} = create_user()

      {:ok, group_1} = create_group()
      {:ok, group_2} = create_group()
      {:ok, group_3} = create_group()

      create_group_user(%{group_id: group_1.id, user_id: user_1.id})
      create_group_user(%{group_id: group_2.id, user_id: user_1.id})

      create_group_user(%{group_id: group_1.id, user_id: user_2.id})
      create_group_user(%{group_id: group_2.id, user_id: user_3.id})

      {:ok, tenant_1} = create_tenant()
      {:ok, tenant_2} = create_tenant()
      {:ok, tenant_3} = create_tenant()

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          tenant_id: tenant_1.id,
          read: true,
          resource_name: "tenant"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          tenant_id: tenant_2.id,
          read: true,
          resource_name: "user"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          tenant_id: tenant_3.id,
          read: false,
          resource_name: "tenant"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_2.id,
          tenant_id: tenant_1.id,
          read: true,
          resource_name: "user"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          tenant_id: tenant_1.id,
          resource_name: "tenant"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          tenant_id: tenant_2.id,
          resource_name: "tenant"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          tenant_id: tenant_3.id,
          resource_name: "tenant"
        })

      conn = TenantsCount.call(conn, [])

      assert conn.assigns[:tenants_count] == 1
    end

    test "when user is not logged in tenants_count is 0", %{conn: conn} do
      conn = TenantsCount.call(conn, [])

      assert conn.assigns[:tenants_count] == 0
    end
  end
end
