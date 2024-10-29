defmodule OmedisWeb.GroupLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.Fixtures

  setup do
    {:ok, owner} = create_user()
    {:ok, another_user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, tenant_2} = create_tenant(%{owner_id: another_user.id})

    %{
      another_user: another_user,
      owner: owner,
      tenant_2: tenant_2,
      tenant: tenant
    }
  end

  describe "/tenants/:slug/groups" do
    test "list groups with pagination", %{
      another_user: another_user,
      conn: conn,
      owner: owner,
      tenant: tenant,
      tenant_2: tenant_2
    } do
      conn = log_in_user(conn, owner)

      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(%{
            tenant_id: tenant.id,
            user_id: owner.id,
            slug: "group-#{i}",
            name: "Group #{i}"
          })

        create_group_user(%{user_id: owner.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant.id,
          group_id: group.id,
          read: true
        })
      end)

      Enum.each(16..30, fn i ->
        {:ok, group} =
          create_group(%{
            tenant_id: tenant.id,
            user_id: owner.id,
            slug: "group-#{i}",
            name: "Group #{i}"
          })

        create_group_user(%{user_id: owner.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant.id,
          group_id: group.id,
          read: false
        })
      end)

      Enum.each(31..40, fn i ->
        {:ok, group} =
          create_group(%{
            tenant_id: tenant_2.id,
            user_id: another_user.id,
            slug: "group-#{i}",
            name: "Group #{i}"
          })

        create_group_user(%{user_id: another_user.id, group_id: group.id})

        create_access_right(%{
          resource_name: "Group",
          tenant_id: tenant_2.id,
          group_id: group.id,
          read: false
        })
      end)

      {:ok, view, html} = live(conn, ~p"/tenants/#{tenant.slug}/groups")

      assert html =~ "Listing Groups"
      assert html =~ "New Group"
      assert html =~ "Group 1"
      assert html =~ "Group 10"
      refute html =~ "Group 11"

      assert view |> element("nav[aria-label=Pagination]") |> has_element?()

      view
      |> element("nav[aria-label=Pagination] a", "3")
      |> render_click()

      # # There is no next page
      refute view |> element("nav[aria-label=Pagination] a", "4") |> has_element?()

      html = render(view)
      assert html =~ "Group 21"
      refute html =~ "Group 16"
      refute html =~ "Group 37"
    end

    test "edit and delete actions are hidden is user has no rights to write or update a group", %{
      conn: conn,
      owner: owner
    } do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: owner.id, slug: "group-1", name: "Group 1"})

      create_group_user(%{user_id: owner.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Tenant",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: false,
        update: false
      })

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: false,
        update: false
      })

      {:ok, view, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/groups")

      refute view |> element("#edit-group-#{group.id}") |> has_element?()
      refute view |> element("#delete-group-#{group.id}") |> has_element?()

      assert html =~ group.name
    end

    test "authorized user can delete a group", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      conn = log_in_user(conn, owner)

      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: owner.id, slug: "group-1", name: "Group 1"})

      create_group_user(%{user_id: owner.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: true,
        update: true
      })

      {:ok, view, _html} = live(conn, ~p"/tenants/#{tenant.slug}/groups")

      assert view
             |> element("#delete-group-#{group.id}")
             |> has_element?()

      assert {:ok, conn} =
               view
               |> element("#delete-group-#{group.id}")
               |> render_click()
               |> follow_redirect(conn)

      html = html_response(conn, 200)

      refute html =~ group.name
    end
  end

  describe "/tenants/:slug/groups/:slug/edit" do
    test "authorized user can edit a group", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      conn = log_in_user(conn, owner)

      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: owner.id, slug: "group-1", name: "Group 1"})

      create_group_user(%{user_id: owner.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: true,
        update: true
      })

      {:ok, view, html} = live(conn, ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/edit")

      assert html =~ "Edit Group"

      html =
        view
        |> form("#group-form", group: %{name: "New Group Name", slug: "new-group-name"})
        |> render_submit()

      assert html =~ "Group updated successfully"
      assert html =~ "New Group Name"
    end

    test "can't edit a group if not authorized", %{
      conn: conn,
      owner: owner
    } do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: owner.id, slug: "group-1", name: "Group 1"})

      create_group_user(%{user_id: owner.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Tenant",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: false,
        update: false
      })

      create_access_right(%{
        resource_name: "Group",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true,
        write: false,
        update: false
      })

      {:error, {:redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/edit")

      assert path == ~p"/tenants/#{tenant.slug}/groups"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
