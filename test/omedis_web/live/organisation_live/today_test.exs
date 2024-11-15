defmodule OmedisWeb.OrganisationLive.TodayTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})
    {:ok, organisation} = create_organisation(%{owner_id: owner.id}, actor: owner)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)

    {:ok, activity} =
      create_activity(organisation, %{
        group_id: group.id,
        is_default: true,
        project_id: project.id
      })

    {:ok, authorized_user} =
      create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})

    {:ok, user} = create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

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
        resource_name: "Project"
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
        resource_name: "Activity"
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

  describe "/organisations/:slug/today" do
    alias Omedis.Accounts.Event

    test "organisation owner can create a new event", %{
      conn: conn,
      group: group,
      activity: activity,
      owner: owner,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      assert lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      {:ok, [event]} =
        Event.by_activity_today(
          %{activity_id: activity.id},
          actor: owner,
          tenant: organisation
        )

      assert event.activity_id == activity.id
      assert event.user_id == owner.id
      assert event.organisation_id == organisation.id
    end

    test "organisation owner can stop active event when selecting same activity again", %{
      conn: conn,
      group: group,
      activity: activity,
      owner: owner,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      # Create a event
      assert lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      # Click same activity again to stop it
      refute lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      # Verify event was stopped (end_at was set)
      {:ok, [event]} =
        Event.by_activity_today(
          %{activity_id: activity.id},
          actor: owner,
          tenant: organisation
        )

      assert event.activity_id == activity.id
      assert not is_nil(event.dtend)
    end

    test "organisation owner can switch active event by selecting different activity", %{
      conn: conn,
      group: group,
      owner: owner,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, activity_1} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 1"
        })

      {:ok, activity_2} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 2"
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      # Start event for the first activity
      assert lv
             |> element("#activity-#{activity_1.id}")
             |> render_click() =~ "active-activity-#{activity_1.id}"

      # Switch to second activity
      assert lv
             |> element("#activity-#{activity_2.id}")
             |> render_click() =~ "active-activity-#{activity_2.id}"

      # Verify first event was stopped
      {:ok, [event_1]} =
        Event.by_activity_today(
          %{activity_id: activity_1.id},
          actor: owner,
          tenant: organisation
        )

      assert not is_nil(event_1.dtend)

      # Verify second event is active
      {:ok, events_2} =
        Event.by_activity_today(
          %{activity_id: activity_2.id},
          actor: owner,
          tenant: organisation
        )

      event_2 = List.last(events_2)
      assert is_nil(event_2.dtend)
    end

    test "authorized user can create a new event", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      activity: activity,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      assert lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      {:ok, [event]} =
        Event.by_activity_today(
          %{activity_id: activity.id},
          actor: authorized_user,
          tenant: organisation
        )

      assert event.activity_id == activity.id
      assert event.user_id == authorized_user.id
      assert event.organisation_id == organisation.id
    end

    test "authorized user can stop active event when selecting same activity again", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      activity: activity,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      # Create a event
      assert lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      # Click same activity again to stop it
      refute lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      # Verify event was stopped (end_at was set)
      {:ok, [event]} =
        Event.by_activity_today(
          %{activity_id: activity.id},
          actor: authorized_user,
          tenant: organisation
        )

      assert event.activity_id == activity.id
      assert not is_nil(event.dtend)
    end

    test "authorized user can switch active event by selecting different activity", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      project: project,
      organisation: organisation
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Event",
          write: true
        })

      {:ok, activity_1} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 1"
        })

      {:ok, activity_2} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 2"
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      # Start event for the first activity
      assert lv
             |> element("#activity-#{activity_1.id}")
             |> render_click() =~ "active-activity-#{activity_1.id}"

      # Switch to second activity
      assert lv
             |> element("#activity-#{activity_2.id}")
             |> render_click() =~ "active-activity-#{activity_2.id}"

      # Verify first event was stopped
      {:ok, [event_1]} =
        Event.by_activity_today(
          %{activity_id: activity_1.id},
          actor: authorized_user,
          tenant: organisation
        )

      assert not is_nil(event_1.dtend)

      # Verify second event is active
      {:ok, events_2} =
        Event.by_activity_today(
          %{activity_id: activity_2.id},
          actor: authorized_user,
          tenant: organisation
        )

      event_2 = List.last(events_2)
      assert is_nil(event_2.dtend)
    end

    test "unauthorized user cannot create events", %{
      conn: conn,
      group: group,
      activity: activity,
      project: project,
      organisation: organisation,
      user: unauthorized_user
    } do
      {:ok, group2} = create_group(organisation)

      {:ok, _} =
        create_group_membership(organisation, %{
          group_id: group2.id,
          user_id: unauthorized_user.id
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          resource_name: "Organisation"
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
          resource_name: "Group"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          resource_name: "Activity"
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      refute lv
             |> element("#activity-#{activity.id}")
             |> render_click() =~ "active-activity-#{activity.id}"

      assert {:ok, []} =
               Event.by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
