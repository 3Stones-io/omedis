defmodule OmedisWeb.EventLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
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
        resource_name: "Event",
        create: true
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

  describe "/organisations/:slug/activities/:id/events" do
    test "organisation owner can see all events", %{
      activity: activity,
      conn: conn,
      organisation: organisation,
      owner: owner,
      user: user
    } do
      after_one_second = DateTime.add(DateTime.utc_now(), 1, :second)
      after_two_seconds = DateTime.add(DateTime.utc_now(), 2, :second)

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: user.id,
            summary: "User's event"
          },
          actor: user
        )

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_two_seconds,
            user_id: owner.id,
            summary: "Owner's event"
          },
          actor: owner
        )

      {:ok, _lv, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/events")

      assert html =~ "User&#39;s event"
      assert html =~ "Owner&#39;s event"
    end

    test "authorized user can see all events", %{
      authorized_user: authorized_user,
      conn: conn,
      activity: activity,
      organisation: organisation,
      user: user
    } do
      after_one_second = DateTime.add(DateTime.utc_now(), 1, :second)
      after_two_seconds = DateTime.add(DateTime.utc_now(), 2, :second)

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: authorized_user.id,
            summary: "Test summary 1"
          },
          actor: authorized_user
        )

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_two_seconds,
            user_id: user.id,
            summary: "Test summary 2"
          },
          actor: user
        )

      {:ok, _lv, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/events")

      assert html =~ "Test summary 1"
      assert html =~ "Test summary 2"
    end

    test "unauthorized user cannot see events", %{conn: conn, user: user} do
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
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id,
            summary: "Test summary"
          },
          actor: user
        )

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation}/activities/#{activity.id}/events")

      refute html =~ "Test summary"
    end
  end
end
