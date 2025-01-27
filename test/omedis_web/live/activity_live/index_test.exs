defmodule OmedisWeb.ActivityLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils
  alias Omedis.TimeTracking.Activity

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

    {:ok, group2} = create_group(organisation)

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

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test2@user.com", groups: [group2.id]})

    {:ok, user} =
      create_user(%{email: "test2@user.com", current_organisation_id: organisation.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      project: project,
      organisation: organisation,
      user: user
    }
  end

  describe "/groups/:group_slug/activities" do
    test "lists all activities if user is organisation owner", %{
      conn: conn,
      group: group,
      project: project,
      organisation: organisation,
      owner: owner
    } do
      {:ok, _activity} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities")

      assert html =~ "Test Activity"
    end

    test "lists all activities if user is authorized", %{
      conn: conn,
      group: group,
      project: project,
      organisation: organisation,
      owner: owner
    } do
      {:ok, _activity} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities")

      assert html =~ "Test Activity"
    end

    test "unauthorized user cannot see activities", %{
      conn: conn,
      group: group,
      project: project,
      organisation: organisation,
      user: user
    } do
      {:ok, _activity} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/groups/#{group}/activities")

      refute html =~ "Test Activity"
      refute html =~ "New Activity"
    end
  end

  describe "/groups/:group_slug/activities/new" do
    test "organisation owner can create new activity", %{
      conn: conn,
      group: group,
      project: project,
      owner: owner
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities/new")

      assert html =~ "New Activity"

      assert html =
               view
               |> form("#activity-form",
                 activity: %{
                   name: "New Activity",
                   project_id: project.id
                 }
               )
               |> render_submit()

      assert_patch(
        view,
        ~p"/groups/#{group}/activities"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "New Activity"
    end

    test "authorized user can create new activity", %{
      conn: conn,
      group: group,
      project: project,
      authorized_user: authorized_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/new")

      assert html =~ "New Activity"

      assert html =
               view
               |> form("#activity-form",
                 activity: %{
                   name: "New Activity",
                   project_id: project.id
                 }
               )
               |> render_submit()

      assert_patch(
        view,
        ~p"/groups/#{group}/activities"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "New Activity"
    end

    test "unauthorized user cannot create new activity", %{
      conn: conn,
      group: group,
      user: user
    } do
      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/groups/#{group}/activities/new")

      assert to == ~p"/groups/#{group}/activities"
      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors", %{
      conn: conn,
      group: group,
      authorized_user: authorized_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/new")

      html =
        view
        |> form("#activity-form", activity: %{name: ""})
        |> render_change()

      assert html =~ "must be present"
    end

    test "user cannot create activity with existing color code", %{
      conn: conn,
      group: group,
      project: project,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _activity} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity",
          color_code: "#000000"
        })

      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities/new")

      html =
        view
        |> form("#activity-form",
          activity: %{
            name: "New Activity",
            color_code: "#000000",
            project_id: project.id
          }
        )
        |> render_submit()

      assert html =~ "has already been taken"
    end
  end

  describe "position updates" do
    test "authorized user can move activities up and down", %{
      conn: conn,
      group: group,
      organisation: organisation,
      project: project,
      authorized_user: authorized_user
    } do
      # Create activities with sequential positions
      activities =
        Enum.map(1..3, fn i ->
          {:ok, activity} =
            create_activity(organisation, %{
              group_id: group.id,
              project_id: project.id,
              name: "Activity #{i}"
            })

          activity
        end)

      [first, second, third] = activities

      {:ok, view, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/groups/#{group}/activities")

      # Verify position controls are rendered
      assert html =~ "move-up-#{second.id}"
      assert html =~ "move-down-#{second.id}"

      # Test moving up
      assert view
             |> element("#move-up-#{second.id}")
             |> render_click()

      :timer.sleep(100)

      # Verify positions after moving up
      assert Ash.get!(Activity, second.id, authorize?: false, tenant: organisation).position == 1
      assert Ash.get!(Activity, first.id, authorize?: false, tenant: organisation).position == 2
      assert Ash.get!(Activity, third.id, authorize?: false, tenant: organisation).position == 3
    end

    test "unauthorized user cannot see position controls", %{
      conn: conn,
      group: group,
      organisation: organisation,
      project: project,
      user: unauthorized_user
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, view, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/groups/#{group}/activities")

      refute html =~ "move-up-#{activity.id}"
      refute html =~ "move-down-#{activity.id}"
      refute view |> element(".position-up") |> has_element?()
      refute view |> element(".position-down") |> has_element?()
    end

    test "organisation owner can move activities up and down", %{
      conn: conn,
      group: group,
      organisation: organisation,
      project: project,
      owner: owner
    } do
      activities =
        Enum.map(1..3, fn i ->
          {:ok, activity} =
            create_activity(organisation, %{
              group_id: group.id,
              project_id: project.id,
              name: "Activity #{i}"
            })

          activity
        end)

      [first, second, third] = activities

      {:ok, view, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups/#{group}/activities")

      # Test moving up
      view
      |> element("#move-up-#{second.id}")
      |> render_click()

      :timer.sleep(100)

      # Verify positions after moving up
      assert Ash.get!(Activity, second.id, authorize?: false, tenant: organisation).position == 1
      assert Ash.get!(Activity, first.id, authorize?: false, tenant: organisation).position == 2
      assert Ash.get!(Activity, third.id, authorize?: false, tenant: organisation).position == 3

      # Test moving down
      view
      |> element("#move-down-#{first.id}")
      |> render_click()

      # Verify positions after moving down
      assert Ash.get!(Activity, second.id, authorize?: false, tenant: organisation).position == 1
      assert Ash.get!(Activity, third.id, authorize?: false, tenant: organisation).position == 2
      assert Ash.get!(Activity, first.id, authorize?: false, tenant: organisation).position == 3
    end
  end
end
