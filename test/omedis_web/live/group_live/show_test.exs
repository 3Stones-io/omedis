defmodule OmedisWeb.GroupLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, user} = create_user()

    {:ok, tenant} = create_tenant(%{owner_id: user.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})

    create_group_user(%{group_id: group.id, user_id: user.id})

    create_access_right(%{
      group_id: group.id,
      resource_name: "Group",
      tenant_id: tenant.id,
      read: true,
      write: true
    })

    %{
      group: group,
      tenant: tenant,
      user: user
    }
  end

  describe "/tenants/:slug/groups/:group_slug" do
    test "renders group details if user is the tenant owner", %{
      conn: conn,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}")

      assert html =~ "Slug"
      assert html =~ group.name
    end

    test "renders group details is a user is authorized", %{
      conn: conn,
      tenant: tenant
    } do
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(%{name: "Test Group", tenant_id: tenant.id})

      create_group_user(%{
        group_id: group.id,
        user_id: authorized_user.id
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        read: true,
        write: true
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "Group",
        tenant_id: tenant.id,
        read: true,
        write: true
      })

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}")

      assert html =~ "Test Group"
    end

    test "does not render a group details if user is unauthorized", %{
      conn: conn,
      user: user
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      create_group_user(%{group_id: group.id, user_id: user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "Group",
        tenant_id: tenant.id,
        read: false,
        write: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}")
      end
    end
  end
end
