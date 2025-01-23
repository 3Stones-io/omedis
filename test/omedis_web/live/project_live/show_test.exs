defmodule OmedisWeb.ProjectLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test@user.com", groups: [group.id]})

    {:ok, authorized_user} =
      create_user(%{email: "test@user.com", current_organisation_id: organisation.id})

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

  describe "/projects/:id" do
    test "renders project details if user is the organisation owner", %{
      conn: conn,
      group: group,
      organisation: organisation,
      owner: owner
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          update: true
        })

      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/projects/#{project.id}")

      assert html =~ "Project"
      assert html =~ project.name
      assert html =~ "Edit Project"
    end

    test "renders project details if user is authorized", %{
      conn: conn,
      group: group,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          update: true
        })

      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects/#{project.id}")

      assert html =~ "Project"
      assert html =~ "Edit Project"
      assert html =~ project.name
    end

    test "does not render project details if user is unauthorized", %{
      conn: conn,
      organisation: organisation,
      user: user
    } do
      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/projects/#{project.id}")
      end
    end
  end

  describe "/projects/:id/show/edit" do
    test "allows updating a project if user is the organisation owner", %{
      conn: conn,
      group: group,
      organisation: organisation,
      owner: owner
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          update: true
        })

      params = %{name: "Test Project"}
      {:ok, project} = create_project(organisation, params)

      {:ok, index_live, _} =
        conn
        |> log_in_user(owner)
        |> live(~p"/projects/#{project.id}/show/edit")

      params = Map.put(params, :name, "Updated Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects/#{project.id}")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "allows updating a project if user is authorized", %{
      conn: conn,
      group: group,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          update: true
        })

      params = %{name: "Test Project"}
      {:ok, project} = create_project(organisation, params)

      {:ok, index_live, _} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/projects/#{project.id}/show/edit")

      params = Map.put(params, :name, "Updated Project")

      assert html =
               index_live
               |> form("#project-form", project: params)
               |> render_submit()

      assert_patch(index_live, ~p"/projects/#{project.id}")

      assert html =~ "Project saved."
      assert html =~ "Updated Project"
    end

    test "doesn't allow updating a project if user is unauthorized", %{
      conn: conn,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          update: false
        })

      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      {:error, {:live_redirect, %{to: redirect_path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/projects/#{project.id}/show/edit")

      assert redirect_path == ~p"/projects/#{project.id}"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
