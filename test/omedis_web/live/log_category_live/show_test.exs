defmodule OmedisWeb.ActivityLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

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

    {:ok, activity} =
      create_activity(%{
        group_id: group.id,
        project_id: project.id,
        name: "Test Activity"
      })

    {:ok, user} = create_user()
    {:ok, group2} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_user(%{group_id: group2.id, user_id: user.id})

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
      activity: activity,
      owner: owner,
      project: project,
      tenant: tenant,
      user: user
    }
  end

  describe "/tenants/:slug/groups/:group_slug/activities/:id" do
    test "shows activity details if user is tenant owner", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      owner: owner
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit activity"
    end

    test "shows activity details if user is authorized", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}")

      assert html =~ activity.name
      assert html =~ "Edit activity"
    end

    test "unauthorized user cannot see activity details", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      user: user
    } do
      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}")
      end
    end
  end

  describe "/tenants/:slug/groups/:group_slug/activities/:id/show/edit" do
    test "tenant owner can edit activity", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      owner: owner
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}/show/edit"
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
        ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "Updated Activity"
    end

    test "authorized user can edit activity", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, show_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}/show/edit"
        )

      assert html =~ "Edit activity"

      assert html =
               show_live
               |> form("#activity-form", activity: %{name: "Updated Activity"})
               |> render_submit()

      assert_patch(
        show_live,
        ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}"
      )

      assert html =~ "Activity saved successfully"
      assert html =~ "Updated Activity"
    end

    test "unauthorized user cannot edit activity", %{
      conn: conn,
      group: group,
      group2: group2,
      activity: activity,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_access_right(%{
          group_id: group2.id,
          read: true,
          resource_name: "Activity",
          tenant_id: tenant.id,
          update: false,
          write: false
        })

      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}/show/edit"
        )

      assert to ==
               ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}"

      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors on edit", %{
      conn: conn,
      group: group,
      activity: activity,
      tenant: tenant,
      authorized_user: authorized_user
    } do
      {:ok, form_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/tenants/#{tenant.slug}/groups/#{group.slug}/activities/#{activity.id}/show/edit"
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
