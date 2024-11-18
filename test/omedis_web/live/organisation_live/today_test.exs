defmodule OmedisWeb.OrganisationLive.TodayTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Event
  alias Omedis.Accounts.Group

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
    test "navigating to today view redirects one to the today view for the latest group and project",
         %{
           conn: conn,
           organisation: organisation,
           owner: owner,
           project: project
         } do
      {:ok, %{results: groups}} =
        Group.by_organisation_id(%{organisation_id: organisation.id},
          actor: owner,
          tenant: organisation
        )

      latest_group = Enum.min_by(groups, & &1.created_at)

      {:error, {:live_redirect, %{to: path}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/today")

      assert path ==
               ~p"/organisations/#{organisation}/today?group_id=#{latest_group.id}&project_id=#{project.id}"
    end

    test "shows a drop down list of groups and navigates to group today page when different group is selected",
         %{
           conn: conn,
           group: group,
           organisation: organisation,
           owner: owner,
           project: project
         } do
      {:ok, group2} = create_group(organisation)

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      lv
      |> element("#group-select-form")
      |> render_change(%{"group_id" => group2.id})

      assert_redirect(
        lv,
        ~p"/organisations/#{organisation}/today?group_id=#{group2.id}&project_id=#{project.id}"
      )
    end

    test "shows a drop down list of projects and navigates to project today page when different project is selected",
         %{
           conn: conn,
           group: group,
           organisation: organisation,
           owner: owner,
           project: project
         } do
      {:ok, project2} = create_project(organisation)

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
        )

      lv
      |> element("#project-select-form")
      |> render_change(%{"project_id" => project2.id})

      assert_redirect(
        lv,
        ~p"/organisations/#{organisation}/today?group_id=#{group.id}&project_id=#{project2.id}"
      )
    end

    test "organisation owner can create a new event by clicking on the start_event button", %{
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
             |> element("#start-activity-#{activity.id}")
             |> render_click() =~ "stop-current-activity-#{activity.id}"

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

    test "organisation owner can stop active event when clicking on the stop_event button", %{
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
             |> element("#start-activity-#{activity.id}")
             |> render_click() =~ "stop-current-activity-#{activity.id}"

      assert lv
             |> element("#stop-current-activity-#{activity.id}")
             |> render_click() =~ "start-activity-#{activity.id}"

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

    test "authorized user can create a new event by clicking on the start_event button", %{
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
             |> element("#start-activity-#{activity.id}")
             |> render_click() =~ "stop-current-activity-#{activity.id}"

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

    test "authorized user can stop active event by clicking on the stop_event button", %{
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
             |> element("#start-activity-#{activity.id}")
             |> render_click() =~ "stop-current-activity-#{activity.id}"

      assert lv
             |> element("#stop-current-activity-#{activity.id}")
             |> render_click() =~ "start-activity-#{activity.id}"

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
             |> element("#start-activity-#{activity.id}")
             |> render_click() =~ "stop-active-activity-#{activity.id}"

      assert {:ok, []} =
               Event.by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
