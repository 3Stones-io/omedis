defmodule OmedisWeb.ProjectLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @create_attrs %{name: "Test Project", position: "1"}

  setup do
    {:ok, tenant} = create_tenant()
    {:ok, user} = create_user()
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

    %{tenant: tenant, user: user, group: group}
  end

  describe "/tenants/:slug/projects" do
    test "lists all projects if user has read access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        read: true,
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Listing Projects"
      assert html =~ project.name
    end

    test "does not list projects if current user has no read access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        read: false,
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Listing Projects"
      refute html =~ project.name
    end

    test "does not show new project link if current user has no create access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        create: false,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute html =~ "New Project"
    end

    test "does not show edit project link if current user has no update access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        write: false,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute html =~ "Edit"
    end
  end

  describe "/tenants/:slug/projects/new" do
    test "renders new project form if current user has create access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        create: true,
        group_id: group.id,
        read: true,
        resource_name: "Project",
        tenant_id: tenant.id
      })

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/new")

      assert html =~ "New Project"

      params = Map.put(@create_attrs, :name, "Dummy Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Project saved."
      assert html =~ "Dummy Project"
    end

    test "does not render new project form if current user has no create access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        create: false,
        group_id: group.id,
        resource_name: "Project",
        tenant_id: tenant.id
      })

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/new")

      refute html =~ "New Project"
      refute html =~ "Use this form to manage project records in your database."
      assert html =~ "You are not authorized to access this page"
      assert redirected_to(conn, 302) == ~p"/tenants/#{tenant.slug}/projects"
    end
  end

  describe "/tenants/:slug/projects/:id/edit" do
    test "allows updating a project if current user has update access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        read: true,
        update: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, _} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      params = %{name: "Updated Project"}

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "doesn't allow updating a project if current user has no update access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        read: true,
        update: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} =
        create_project(Map.put(@create_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      refute html =~ "Use this form to manage project records in your database."
      assert html =~ "You are not authorized to access this page"
      assert redirected_to(conn, 302) == ~p"/tenants/#{tenant.slug}/projects"
    end
  end
end
