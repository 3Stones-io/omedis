defmodule OmedisWeb.LogCategoryLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.LogCategory

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
      read: true,
      resource_name: "Group",
      tenant_id: tenant.id,
      write: true,
      update: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "LogCategory",
      tenant_id: tenant.id,
      write: true,
      update: true
    })

    %{
      group: group,
      project: project,
      tenant: tenant,
      user: user
    }
  end

  describe "/tenants/:tenant_slug/groups/:group_slug/log_categories" do
    test "lists all log categories with pagination", %{
      conn: conn,
      user: user,
      tenant: tenant,
      group: group,
      project: project
    } do
      {:ok, group_2} = create_group(%{tenant_id: tenant.id})

      Enum.each(1..15, fn i ->
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Log Category #{i}",
          is_default: false
        })
      end)

      Enum.each(16..30, fn i ->
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Log Category #{i}",
          is_default: false
        })
      end)

      Enum.each(31..40, fn i ->
        create_log_category(%{
          group_id: group_2.id,
          project_id: project.id,
          name: "Log Category #{i}",
          is_default: false
        })
      end)

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "Listing Log categories"
      assert html =~ "Log Category 1"
      assert html =~ "Log Category 10"
      refute html =~ "Log Category 11"

      assert index_live |> element("nav[aria-label=Pagination]") |> has_element?()

      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      refute html =~ "Log Category 10"
      assert html =~ "Log Category 11"
      assert html =~ "Log Category 15"

      index_live
      |> element("nav[aria-label=Pagination] a", "3")
      |> render_click()

      html = render(index_live)
      refute html =~ "Log Category 15"
      refute html =~ "Log Category 16"
      assert html =~ "Log Category 21"

      refute index_live |> element("nav[aria-label=Pagination] a", "4") |> has_element?()
    end

    test "hides edit option for unauthorized users", %{
      conn: conn,
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      {:ok, log_category} =
        create_log_category(%{group_id: group.id, project_id: project.id})

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      refute index_live |> element("#edit-#{log_category.id}") |> has_element?()
    end

    test "user can update a log category if they are tenant owner", %{
      conn: conn,
      user: user,
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, log_category} =
        create_log_category(%{group_id: group.id, project_id: project.id})

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert index_live |> element("#edit-#{log_category.id}") |> has_element?()

      assert index_live
             |> element("#edit-#{log_category.id}")
             |> render_click() =~ "Edit Log category"

      assert index_live
             |> form("#log_category-form", log_category: %{name: "New log category"})
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      html = render(index_live)
      assert html =~ "New log category"
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

      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert index_live |> element("#edit-#{log_category.id}") |> has_element?()

      assert index_live
             |> element("#edit-#{log_category.id}")
             |> render_click() =~ "Edit Log category"

      assert index_live
             |> form("#log_category-form", log_category: %{name: "New log category"})
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      html = render(index_live)
      assert html =~ "New log category"
    end

    test "hides update position control for unauthorized users", %{
      conn: conn,
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      create_log_category(%{group_id: group.id, project_id: project.id})

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      refute index_live |> element(".position-up") |> has_element?()
      refute index_live |> element(".position-down") |> has_element?()
    end

    test "user can update position of a log category if they are the tenant owner", %{
      conn: conn,
      user: user,
      group: group,
      tenant: tenant,
      project: project
    } do
      categories =
        Enum.map(1..3, fn i ->
          {:ok, log_category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id,
              name: "Log Category #{i}"
            })

          log_category
        end)

      [first, second | _] = categories

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert index_live |> element(".position-up") |> has_element?()
      assert index_live |> element(".position-down") |> has_element?()

      index_live
      |> element("#move-up-#{second.id}")
      |> render_click()

      assert Ash.get!(LogCategory, second.id, actor: user, tenant: tenant).position == 1
      assert Ash.get!(LogCategory, first.id, actor: user, tenant: tenant).position == 2

      index_live
      |> element("#move-down-#{second.id}")
      |> render_click()

      assert Ash.get!(LogCategory, first.id, actor: user, tenant: tenant).position == 1
      assert Ash.get!(LogCategory, second.id, actor: user, tenant: tenant).position == 2
    end

    test "authorized users can update log_category positions", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      categories =
        Enum.map(1..3, fn i ->
          {:ok, log_category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id,
              name: "Log Category #{i}"
            })

          log_category
        end)

      [first, second | _] = categories

      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert index_live |> element(".position-up") |> has_element?()
      assert index_live |> element(".position-down") |> has_element?()

      index_live
      |> element("#move-up-#{second.id}")
      |> render_click()

      assert Ash.get!(LogCategory, second.id, actor: authorized_user, tenant: tenant).position ==
               1

      assert Ash.get!(LogCategory, first.id, actor: authorized_user, tenant: tenant).position == 2

      index_live
      |> element("#move-down-#{second.id}")
      |> render_click()

      assert Ash.get!(LogCategory, first.id, actor: authorized_user, tenant: tenant).position == 1

      assert Ash.get!(LogCategory, second.id, actor: authorized_user, tenant: tenant).position ==
               2
    end

    test "shows create button for authorized users", %{
      conn: conn,
      user: user,
      tenant: tenant,
      project: project,
      group: group
    } do
      create_log_category(%{group_id: group.id, project_id: project.id})

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "New Log category"

      assert index_live |> element("a", "New Log category") |> render_click() =~
               "New Log category"

      assert_patch(
        index_live,
        ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/new"
      )
    end

    test "hides create button for unauthorized users", %{
      conn: conn,
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      create_log_category(%{group_id: group.id, project_id: project.id})

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      refute html =~ "New Log category"
    end

    test "user can create a log category if they are the tenant owner", %{
      conn: conn,
      user: user,
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "New Log category"

      assert index_live
             |> element(".new-log-category-button")
             |> render_click() =~ "New Log category"

      assert index_live
             |> form("#log_category-form",
               log_category: %{
                 name: "dolore",
                 slug: "aut-5604",
                 group_id: group.id,
                 color_code: "#1f77b4",
                 is_default: true,
                 project_id: project.id
               }
             )
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")
      html = render(index_live)
      assert html =~ "dolore"
      assert html =~ "Default"
    end

    test "user can create a log category if they are authorized", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      {:ok, index_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "New Log category"

      assert index_live
             |> element(".new-log-category-button")
             |> render_click() =~ "New Log category"

      assert index_live
             |> form("#log_category-form",
               log_category: %{
                 name: "dolore",
                 slug: "aut-5604",
                 group_id: group.id,
                 color_code: "#1f77b4",
                 is_default: true,
                 project_id: project.id
               }
             )
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories")
      html = render(index_live)
      assert html =~ "dolore"
      assert html =~ "Default"
    end
  end

  describe "/tenants/:tenant_slug/groups/:group_slug/log_categories/:log_category/edit" do
    test "unauthorized users cannot access the edit page", %{
      conn: conn,
      user: user,
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, log_category} =
        create_log_category(%{group_id: group.id, project_id: project.id})

      create_group_user(%{group_id: group.id, user_id: user.id})

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/#{log_category.id}/edit"
        )

      assert path == ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end

  describe "/tenants/:tenant_slug/groups/:group_slug/log_categories/new" do
    test "unauthorized users cannot access the create log category page", %{
      conn: conn,
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
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories/new")

      assert path == ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/log_categories"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
