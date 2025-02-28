defmodule OmedisWeb.ProjectLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @create_attrs %{name: "Test Project"}

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id}, actor: owner)
    {:ok, group} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test@user.com", groups: [group.id]})

    {:ok, authorized_user} =
      create_user(%{email: "test@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        create: true,
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    {:ok, another_group} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test2@user.com", groups: [another_group.id]})

    {:ok, user} =
      create_user(%{email: "test2@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: another_group.id,
        read: true,
        resource_name: "Organisation"
      })

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    }
  end

  describe "/projects" do
    test "lists all projects if user is the organisation owner", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      {:ok, _} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/projects")

      assert html =~ "Test Project"
    end

    test "lists all projects if user is authorized", %{
      conn: conn,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects")

      assert html =~ project.name
    end

    test "does not list projects if user is not authorized", %{
      conn: conn,
      organisation: organisation,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/projects")

      refute html =~ project.name
    end

    test "does not show new project link if user is not authorized", %{
      conn: conn,
      organisation: organisation,
      user: unauthorized_user
    } do
      {:ok, _} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/projects")

      refute html =~ "New Project"
    end

    test "does not show edit project link if user is not authorized", %{
      conn: conn,
      organisation: organisation,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/projects")

      refute has_element?(index_live, "#edit-project-#{project.id}")
    end
  end

  describe "/projects/new" do
    test "organisation owner can create new project", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      :ok = OmedisWeb.Endpoint.subscribe("#{organisation.id}:projects")

      {:ok, index_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/projects/new")

      assert html =~ "New Project"

      params = Map.put(@create_attrs, :name, "Dummy Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects")

      assert_broadcast "create", broadcast_payload

      assert %Ash.Notifier.Notification{resource: Omedis.Projects.Project, data: created_project} =
               broadcast_payload

      assert created_project.name == "Dummy Project"

      assert html =~ "Project saved."
      assert html =~ "Dummy Project"
    end

    test "authorized user can create new project", %{
      conn: conn,
      authorized_user: authorized_user
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects/new")

      assert html =~ "New Project"

      params = Map.put(@create_attrs, :name, "Dummy Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects")

      assert html =~ "Project saved."
      assert html =~ "Dummy Project"
    end

    test "shows form errors if invalid data is submitted", %{
      conn: conn,
      authorized_user: authorized_user
    } do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects/new")

      assert html =
               index_live
               |> form("#project-form", project: %{name: ""})
               |> render_change()

      assert html =~ "is required"
    end

    test "unauthorized user cannot create new project", %{
      conn: conn,
      user: unauthorized_user
    } do
      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/projects/new")

      assert redirect_path == ~p"/projects"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end

  describe "/projects/:id/edit" do
    test "organisation owner can edit project", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(owner)
        |> live(~p"/projects/#{project.id}/edit")

      params = %{name: "Updated Project"}

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "authorized user can edit project", %{
      conn: conn,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, index_live, _} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects/#{project.id}/edit")

      params = %{name: "Updated Project"}

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "unauthorized user cannot edit project", %{
      conn: conn,
      organisation: organisation,
      user: unauthorized_user
    } do
      {:ok, project} = create_project(organisation, %{name: "Test Project"})

      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/projects/#{project.id}/edit")

      assert redirect_path == ~p"/projects"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
