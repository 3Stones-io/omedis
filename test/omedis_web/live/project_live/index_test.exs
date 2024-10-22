defmodule OmedisWeb.ProjectLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.Fixtures

  alias Omedis.Accounts.Project

  @create_attrs %{name: "Test Project", position: "1"}
  @update_attrs %{name: "Updated Project"}

  setup do
    {:ok, tenant} = create_tenant()
    {:ok, user} = create_user()
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

    %{tenant: tenant, user: user, group: group}
  end

  describe "Index" do
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

    test "doesn't list projects without read access", %{
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

    test "allows creating a new project with create access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        # read: true,
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, index_live, _} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert index_live
             |> element("a", "New Project")
             |> render_click() =~ "New Project"

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects/new")

      assert index_live
             |> form("#project-form", project: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      html = render(index_live)
      assert html =~ "Project saved."
      assert html =~ "Test Project"
    end

    test "doesn't allow creating a new project without create access", %{
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

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute has_element?(index_live, "a", "New Project")
    end

    test "allows updating a project with update access", %{
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

      {:ok, project} = create_project(Map.put(@create_attrs, :tenant_id, tenant.id))

      {:ok, index_live, _} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert index_live
             |> element("#projects-#{project.id} a", "Edit")
             |> render_click() =~ "Edit Project"

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects/#{project}/edit")

      assert index_live
             |> form("#project-form", project: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      html = render(index_live)
      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "doesn't allow updating a project without update access", %{
      conn: conn,
      tenant: tenant,
      user: user,
      group: group
    } do
      create_access_right(%{
        resource_name: "Project",
        read: true,
        update: false,
        tenant_id: tenant.id,
        group_id: group.id
      })

      {:ok, project} = create_project(Map.put(@create_attrs, :tenant_id, tenant.id))

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute has_element?(index_live, "#projects-#{project.id} a", "Edit")
    end
  end
end
