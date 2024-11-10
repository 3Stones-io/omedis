defmodule OmedisWeb.LogEntryLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, activity} = create_activity(organisation, %{group_id: group.id, project_id: project.id})
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

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
        resource_name: "Activity"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "LogEntry",
        write: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    %{
      authorized_user: authorized_user,
      group: group,
      activity: activity,
      owner: owner,
      project: project,
      organisation: organisation,
      user: user
    }
  end

  describe "/organisations/:slug/activities/:id/log_entries" do
    test "organisation owner can see all log entries", %{
      activity: activity,
      conn: conn,
      organisation: organisation,
      owner: owner,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          comment: "User's log entry"
        })

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: owner.id,
          comment: "Owner's log entry"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/log_entries")

      assert html =~ "User&#39;s log entry"
      assert html =~ "Owner&#39;s log entry"
    end

    test "authorized user can see all log entries", %{
      authorized_user: authorized_user,
      conn: conn,
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: authorized_user.id,
          comment: "Test comment 1"
        })

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          comment: "Test comment 2"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/log_entries")

      assert html =~ "Test comment 1"
      assert html =~ "Test comment 2"
    end

    test "unauthorized user cannot see log entries", %{conn: conn, user: user} do
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})
      {:ok, project} = create_project(organisation)

      {:ok, activity} =
        create_activity(organisation, %{group_id: group.id, project_id: project.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Activity"
        })

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          comment: "Test comment"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/log_entries")

      refute html =~ "Test comment"
    end
  end
end
