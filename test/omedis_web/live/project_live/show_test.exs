defmodule OmedisWeb.ProjectLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @update_attrs %{name: "Test Project", position: "1"}

  setup do
    {:ok, tenant} = create_tenant()
    {:ok, user} = create_user()
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

    %{tenant: tenant, user: user, group: group}
  end

  describe "/tenants/:slug/projects/:id" do
    test "renders project details if current user has read access", %{
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

      {:ok, project} =
        create_project(Map.put(@update_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}")

      assert html =~ "Project"
      assert html =~ "Edit project"
      assert html =~ project.name
    end

    test "does not render project details if current user has no read access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        create: true,
        group_id: group.id,
        read: false,
        resource_name: "Project",
        tenant_id: tenant.id
      })

      {:ok, project} =
        create_project(Map.put(@update_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}")

      refute html =~ "Project"
      refute html =~ "Edit project"
      refute html =~ project.name
      assert html =~ "Listing Projects"
    end
  end

  describe "/tenants/:slug/projects/:id/show/edit" do
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
        create_project(Map.put(@update_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

      {:ok, index_live, _} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      params = Map.put(@update_attrs, :name, "Updated Project")

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
        create_project(Map.put(@update_attrs, :tenant_id, tenant.id), actor: user, tenant: tenant)

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
