defmodule OmedisWeb.ActivityLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Activity

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Activity",
        tenant_id: tenant.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

    {:ok, user} = create_user()
    {:ok, group2} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_membership(%{group_id: group2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Group",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Project",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

    %{
      authorized_user: authorized_user,
      group: group,
      group2: group2,
      owner: owner,
      project: project,
      tenant: tenant,
      user: user
    }
  end

  describe "/tenants/:slug/groups/:group_slug/activities" do
    test "lists all activities if user is tenant owner", %{
      conn: conn,
      group: group,
      project: project,
      tenant: tenant,
      owner: owner
    } do
      {:ok, _activity} =
        create_activity(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      assert html =~ "Test Activity"
    end

    test "lists all activities if user is authorized", %{
      conn: conn,
      group: group,
      project: project,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, _activity} =
        create_activity(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      assert html =~ "Test Activity"
    end

    test "unauthorized user cannot see activities", %{
      conn: conn,
      group: group,
      project: project,
      tenant: tenant,
      user: user
    } do
      {:ok, _activity} =
        create_activity(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      refute html =~ "Test Activity"
      refute html =~ "New Activity"
    end
  end

  describe "/tenants/:slug/groups/:group_slug/activities/new" do
    test "tenant owner can create new activity", %{
      conn: conn,
      group: group,
      project: project,
      tenant: tenant,
      owner: owner
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities/new")

      assert html =~ "New Activity"

      assert html =
               view
               |> form("#activity-form",
                 activity: %{
                   name: "New Activity",
                   project_id: project.id,
                   slug: "new-activity"
                 }
               )
               |> render_submit()

      assert_patch(view, ~p"/tenants/#{tenant}/groups/#{group}/activities")

      assert html =~ "Activity saved successfully"
      assert html =~ "New Activity"
    end

    test "authorized user can create new activity", %{
      conn: conn,
      group: group,
      project: project,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities/new")

      assert html =~ "New Activity"

      assert html =
               view
               |> form("#activity-form",
                 activity: %{
                   name: "New Activity",
                   project_id: project.id,
                   slug: "new-activity"
                 }
               )
               |> render_submit()

      assert_patch(view, ~p"/tenants/#{tenant}/groups/#{group}/activities")

      assert html =~ "Activity saved successfully"
      assert html =~ "New Activity"
    end

    test "unauthorized user cannot create new activity", %{
      conn: conn,
      group: group,
      tenant: tenant,
      user: user
    } do
      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities/new")

      assert to == ~p"/tenants/#{tenant}/groups/#{group}/activities"
      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors", %{
      conn: conn,
      group: group,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities/new")

      html =
        view
        |> form("#activity-form", activity: %{name: "", slug: ""})
        |> render_change()

      assert html =~ "must be present"
    end
  end

  describe "position updates" do
    test "authorized user can move activities up and down", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project,
      authorized_user: authorized_user
    } do
      # Create activities with sequential positions
      activities =
        Enum.map(1..3, fn i ->
          {:ok, activity} =
            create_activity(%{
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
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      # Verify position controls are rendered
      assert html =~ "move-up-#{second.id}"
      assert html =~ "move-down-#{second.id}"

      # Test moving up
      assert view
             |> element("#move-up-#{second.id}")
             |> render_click()

      :timer.sleep(100)

      # Verify positions after moving up
      assert Ash.get!(Activity, second.id, authorize?: false).position == 1
      assert Ash.get!(Activity, first.id, authorize?: false).position == 2
      assert Ash.get!(Activity, third.id, authorize?: false).position == 3
    end

    test "unauthorized user cannot see position controls", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project,
      user: unauthorized_user
    } do
      {:ok, activity} =
        create_activity(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Activity"
        })

      {:ok, view, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      refute html =~ "move-up-#{activity.id}"
      refute html =~ "move-down-#{activity.id}"
      refute view |> element(".position-up") |> has_element?()
      refute view |> element(".position-down") |> has_element?()
    end

    test "tenant owner can move activities up and down", %{
      conn: conn,
      group: group,
      tenant: tenant,
      project: project,
      owner: owner
    } do
      activities =
        Enum.map(1..3, fn i ->
          {:ok, activity} =
            create_activity(%{
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
        |> live(~p"/tenants/#{tenant}/groups/#{group}/activities")

      # Test moving up
      view
      |> element("#move-up-#{second.id}")
      |> render_click()

      :timer.sleep(100)

      # Verify positions after moving up
      assert Ash.get!(Activity, second.id, authorize?: false).position == 1
      assert Ash.get!(Activity, first.id, authorize?: false).position == 2
      assert Ash.get!(Activity, third.id, authorize?: false).position == 3

      # Test moving down
      view
      |> element("#move-down-#{first.id}")
      |> render_click()

      # Verify positions after moving down
      assert Ash.get!(Activity, second.id, authorize?: false).position == 1
      assert Ash.get!(Activity, third.id, authorize?: false).position == 2
      assert Ash.get!(Activity, first.id, authorize?: false).position == 3
    end
  end
end
