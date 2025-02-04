defmodule OmedisWeb.ActivityLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test@user.com", groups: [group.id]})

    {:ok, authorized_user} =
      create_user(%{email: "test@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Activity",
        create: true,
        destroy: true,
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Group"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Project"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    {:ok, activity} =
      create_activity(organisation, %{
        group_id: group.id,
        project_id: project.id,
        name: "Test Activity"
      })

    {:ok, group2} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test2@user.com", groups: [group2.id]})

    {:ok, user} =
      create_user(%{email: "test2@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group2.id,
        read: true,
        resource_name: "Group"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group2.id,
        read: true,
        resource_name: "Project"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group2.id,
        read: true,
        resource_name: "Organisation"
      })

    %{
      authorized_user: authorized_user,
      group: group,
      group2: group2,
      activity: activity,
      owner: owner,
      project: project,
      organisation: organisation,
      user: user
    }
  end

  describe "/groups/:group_slug/activities/:id" do
    test "shows activity details if user is organisation owner", %{
      activity: activity,
      conn: conn,
      group: group,
      owner: owner
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit Activity"
    end

    test "shows activity details if user is authorized", %{
      activity: activity,
      authorized_user: authorized_user,
      conn: conn,
      group: group
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit Activity"
    end

    test "unauthorized user cannot see activity details", %{
      activity: activity,
      conn: conn,
      group: group,
      user: user
    } do
      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/groups/#{group}/activities/#{activity.id}")
      end
    end
  end

  describe "/groups/:group_slug/activities/:id/show/edit" do
    test "organisation owner can edit activity", %{
      activity: activity,
      conn: conn,
      group: group,
      owner: owner
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities/#{activity.id}/show/edit")

      assert html =~ "Edit Activity"

      assert html =
               show_live
               |> form("#activity-form",
                 activity: %{
                   name: "Updated Activity"
                 }
               )
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/groups/#{group}/activities/#{activity.id}"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "Updated Activity"
    end

    test "authorized user can edit activity", %{
      conn: conn,
      group: group,
      activity: activity,
      authorized_user: authorized_user
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/#{activity.id}/show/edit")

      assert html =~ "Edit Activity"

      assert html =
               show_live
               |> form("#activity-form", activity: %{name: "Updated Activity"})
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/groups/#{group}/activities/#{activity.id}"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "Updated Activity"
    end

    test "unauthorized user cannot edit activity", %{
      conn: conn,
      group: group,
      group2: group2,
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          resource_name: "Activity",
          update: false
        })

      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/groups/#{group}/activities/#{activity.id}/show/edit")

      assert to ==
               ~p"/groups/#{group}/activities/#{activity.id}"

      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors on edit", %{
      conn: conn,
      group: group,
      activity: activity,
      authorized_user: authorized_user
    } do
      {:ok, form_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/#{activity.id}/show/edit")

      assert html =
               form_live
               |> form("#activity-form", activity: %{name: ""})
               |> render_change()

      assert html =~ "must be present"
    end
  end
end
