defmodule OmedisWeb.ProjectLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

    {:ok, another_group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_user(%{group_id: another_group.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: another_group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

    %{authorized_user: authorized_user, group: group, owner: owner, tenant: tenant, user: user}
  end

  describe "/tenants/:slug/projects/:id" do
    test "renders project details if is the tenant owner", %{
      conn: conn,
      tenant: tenant,
      owner: owner
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}")

      assert html =~ "Project"
      assert html =~ "Edit project"
      assert html =~ project.name
    end

    test "renders project details if user is authorized", %{
      conn: conn,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}")

      assert html =~ "Project"
      assert html =~ "Edit project"
      assert html =~ project.name
    end

    # TODO: Fix this test
    @tag :skip
    test "does not render project details if user is unauthorized", %{
      conn: conn,
      tenant: tenant,
      user: user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:ok, _, html} =
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
    test "allows updating a project if user is the tenant owner", %{
      conn: conn,
      tenant: tenant,
      owner: owner
    } do
      params = %{tenant_id: tenant.id, name: "Test Project", position: "1"}
      {:ok, project} = create_project(params)

      {:ok, index_live, _} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      params = Map.put(params, :name, "Updated Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "allows updating a project if user is authorized", %{
      conn: conn,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      params = %{tenant_id: tenant.id, name: "Test Project", position: "1"}
      {:ok, project} = create_project(params)

      {:ok, index_live, _} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      params = Map.put(params, :name, "Updated Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/tenants/#{tenant.slug}/projects")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "doesn't allow updating a project if user is unauthorized", %{
      conn: conn,
      tenant: tenant,
      user: user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/projects/#{project.id}/edit")

      assert redirect_path == ~p"/tenants/#{tenant.slug}/projects"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
