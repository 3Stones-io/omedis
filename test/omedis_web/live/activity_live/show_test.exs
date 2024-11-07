defmodule OmedisWeb.ActivityLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, project} = create_project(%{organisation_id: organisation.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Activity",
        organisation_id: organisation.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    {:ok, activity} =
      create_activity(%{
        group_id: group.id,
        project_id: project.id,
        name: "Test Activity"
      })

    {:ok, user} = create_user()
    {:ok, group2} = create_group(%{organisation_id: organisation.id})
    {:ok, _} = create_group_membership(%{group_id: group2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
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

  describe "/organisations/:slug/groups/:group_slug/activities/:id" do
    test "shows activity details if user is organisation owner", %{
      activity: activity,
      conn: conn,
      group: group,
      organisation: organisation,
      owner: owner
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit activity"
    end

    test "shows activity details if user is authorized", %{
      activity: activity,
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      organisation: organisation
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit activity"
    end

    test "unauthorized user cannot see activity details", %{
      activity: activity,
      conn: conn,
      group: group,
      organisation: organisation,
      user: user
    } do
      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}")
      end
    end
  end

  describe "/organisations/:slug/groups/:group_slug/activities/:id/show/edit" do
    test "organisation owner can edit activity", %{
      activity: activity,
      conn: conn,
      group: group,
      organisation: organisation,
      owner: owner
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}/show/edit"
        )

      assert html =~ "Edit activity"

      assert html =
               show_live
               |> form("#activity-form",
                 activity: %{
                   name: "Updated Activity",
                   color_code: "#00FF00"
                 }
               )
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "Updated Activity"
    end

    test "authorized user can edit activity", %{
      conn: conn,
      group: group,
      activity: activity,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}/show/edit"
        )

      assert html =~ "Edit activity"

      assert html =
               show_live
               |> form("#activity-form", activity: %{name: "Updated Activity"})
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}"
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
        create_access_right(%{
          group_id: group2.id,
          read: true,
          resource_name: "Activity",
          organisation_id: organisation.id,
          update: false,
          write: false
        })

      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}/show/edit"
        )

      assert to ==
               ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}"

      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors on edit", %{
      conn: conn,
      group: group,
      activity: activity,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, form_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation}/groups/#{group}/activities/#{activity.id}/show/edit"
        )

      assert html =
               form_live
               |> form("#activity-form", activity: %{name: "", color_code: "invalid"})
               |> render_change()

      assert html =~ "must be present"
      assert html =~ "Color code must be a valid hex color code"
    end
  end
end
