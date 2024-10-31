defmodule OmedisWeb.LogCategoryLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: user.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})

    create_group_user(%{group_id: group.id, user_id: user.id})

    create_access_right(%{
      group_id: group.id,
      resource_name: "Tenant",
      tenant_id: tenant.id,
      read: true,
      write: true,
      update: true
    })

    create_access_right(%{
      group_id: group.id,
      resource_name: "LogCategory",
      tenant_id: tenant.id,
      read: true,
      write: true,
      update: true
    })

    {:ok, log_category} =
      create_log_category(%{
        group_id: group.id,
        project_id: project.id,
        name: "Test Category",
        is_default: false
      })

    %{
      user: user,
      tenant: tenant,
      group: group,
      project: project,
      log_category: log_category
    }
  end

  describe "/tenants/:tenant_slug/groups/:group_slug/log_categories/:id" do
    test "tenant owner can view log category details", %{
      conn: conn,
      user: user,
      tenant: tenant,
      group: group,
      log_category: log_category
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      assert html =~ log_category.name
      assert html =~ "Edit log_category"
      assert html =~ "View Log entries"
    end

    test "authorized users can edit a log category", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      {:ok, _show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      assert html =~ log_category.name
      assert html =~ "Edit log_category"
      assert html =~ "View Log entries"
    end

    test "shows edit button when user has update access", %{
      conn: conn,
      user: user,
      tenant: tenant,
      group: group,
      log_category: log_category
    } do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      assert show_live
             |> element("a", "Edit log_category")
             |> render_click() =~ "Edit log_category"

      assert_patch(
        show_live,
        ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
      )

      assert show_live
             |> form("#log_category-form", log_category: %{name: "Updated Category"})
             |> render_submit()

      assert_patch(
        show_live,
        ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
      )

      html = render(show_live)
      assert html =~ "Updated Category"
      assert html =~ "Log category saved successfully"
    end

    test "hides edit button for unauthorized users", %{
      conn: conn,
      tenant: tenant,
      group: group,
      project: project
    } do
      {:ok, unauthorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: unauthorized_user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: true,
        write: false,
        update: false
      })

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      {:ok, _show_live, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      refute html =~ "Edit Log_category"
    end

    test "redirects to log entries page when clicking view entries", %{
      conn: conn,
      user: user,
      tenant: tenant,
      group: group,
      log_category: log_category
    } do
      {:ok, show_live, _html} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )

      show_live
      |> element("a", "View Log entries")
      |> render_click()

      assert_redirect(
        show_live,
        ~p"/tenants/#{tenant.slug}/log_categories/#{log_category}/log_entries"
      )
    end

    test "unauthorized users cannot access the show page", %{
      conn: conn,
      group: group,
      project: project,
      user: user
    } do
      {:ok, tenant} = create_tenant()

      create_group_user(%{group_id: group.id, user_id: user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: false,
        write: false,
        update: false
      })

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"
        )
      end
    end
  end

  describe "/tenants/:tenant_slug/groups/:group_slug/log_categories/:id/show/edit" do
    test "unauthorized users cannot access the edit page", %{
      conn: conn,
      project: project,
      user: user
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      create_group_user(%{group_id: group.id, user_id: user.id})

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: true,
        write: false,
        update: false
      })

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/show/edit"
        )

      assert path ==
               ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}"

      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
