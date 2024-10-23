defmodule OmedisWeb.ProjectLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @create_attrs %{name: "Test Project", position: "1"}

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        tenant_id: tenant.id,
        write: true
      })

    %{authorized_user: authorized_user, group: group, owner: owner, tenant: tenant, user: user}
  end

  describe "/tenants/:slug/projects" do
    test "lists all projects if user is the tenant owner", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      {:ok, _} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Test Project"
    end

    test "lists all projects if user is authorized", %{
      conn: conn,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      assert html =~ project.name
    end

    test "does not list projects if user is not authorized", %{
      conn: conn,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute html =~ project.name
    end

    test "does not show new project link if user is not authorized", %{
      conn: conn,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:ok, _} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute html =~ "New Project"
    end

    test "does not show edit project link if user is not authorized", %{
      conn: conn,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects")

      refute has_element?(index_live, "#edit-project-#{project.id}")
    end
  end

  describe "/tenants/:slug/projects/new" do
    test "tenant owner can create new project", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(owner)
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

    test "authorized user can create new project", %{
      conn: conn,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(authorized_user)
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

    test "unauthorized user cannot create new project", %{
      conn: conn,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects/new")

      assert redirect_path == ~p"/tenants/#{tenant.slug}/projects"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end

  describe "/tenants/:slug/projects/:id/edit" do
    test "tenant owner can edit project", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(owner)
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

    test "authorized user can edit project", %{
      conn: conn,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(authorized_user)
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

    test "unauthorized user cannot edit project", %{
      conn: conn,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      assert redirect_path == ~p"/tenants/#{tenant.slug}/projects"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
