defmodule OmedisWeb.OrganisationLive.TodayTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  require Ash.Query

  alias Omedis.Groups
  alias Omedis.Projects
  alias Omedis.TimeTracking

  setup do
    {:ok, owner} = create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)

    {:ok, [project]} =
      Projects.Project
      |> Ash.Query.filter(name: "Project 1", organisation_id: organisation.id)
      |> Ash.read(actor: owner, tenant: organisation)

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
        resource_name: "Project",
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        update: true
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
      {:ok, [latest_group]} =
        Groups.latest_group_by_organisation_id(%{organisation_id: organisation.id},
          actor: owner,
          tenant: organisation
        )

      {:error, {:live_redirect, %{to: path}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/today")

      assert path ==
               ~p"/organisations/#{organisation}/today?group_id=#{latest_group.id}&project_id=#{project.id}"
    end

    test "redirects to group creation page when no groups exist", %{
      conn: conn,
      organisation: organisation,
      owner: owner
    } do
      {:ok, %{results: groups}} =
        Groups.get_group_by_organisation_id(%{organisation_id: organisation.id},
          actor: owner,
          tenant: organisation
        )

      # Delete all groups
      Enum.each(groups, fn group ->
        :ok = Groups.destroy_group(group, authorize?: false)
      end)

      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/today")

      assert path == ~p"/organisations/#{organisation}/groups/new"
      assert flash["error"] == "No group found. Please create one first."
    end

    test "redirects to project creation page when no projects exist", %{
      conn: conn,
      organisation: organisation,
      owner: owner
    } do
      {:ok, projects} =
        Projects.get_project_by_organisation_id(%{organisation_id: organisation.id},
          actor: owner,
          tenant: organisation
        )

      # Delete all projects
      Enum.each(projects, fn project ->
        :ok = Ash.destroy(project, authorize?: false)
      end)

      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/today")

      assert path == ~p"/organisations/#{organisation}/projects/new"
      assert flash["error"] == "No project found. Please create one first."
    end

    test "updates timestamps for selected group and project", %{
      conn: conn,
      group: group,
      organisation: organisation,
      owner: owner,
      project: project
    } do
      past_datetime = DateTime.add(DateTime.utc_now(), -1, :second)

      # Backdate the updated_at fields to ensure we can detect changes
      {:ok, backdated_group} =
        Groups.update_group(
          group,
          %{},
          context: %{updated_at: past_datetime},
          authorize?: false,
          actor: owner,
          tenant: organisation
        )

      {:ok, backdated_project} =
        Projects.update_project(
          project,
          %{},
          context: %{updated_at: past_datetime},
          authorize?: false,
          actor: owner,
          tenant: organisation
        )

      {:ok, _lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation}/today?group_id=#{backdated_group.id}&project_id=#{backdated_project.id}"
        )

      # Fetch updated records
      {:ok, updated_group} =
        Groups.get_group_by_id(backdated_group.id, actor: owner, tenant: organisation)

      {:ok, updated_project} =
        Projects.get_project_by_id(backdated_project.id, actor: owner, tenant: organisation)

      assert DateTime.compare(updated_group.updated_at, backdated_group.updated_at) == :gt
      assert DateTime.compare(updated_project.updated_at, backdated_project.updated_at) == :gt
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
          create: true
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
        TimeTracking.get_events_by_activity_today(
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
          create: true
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
        TimeTracking.get_events_by_activity_today(
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
          create: true
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
        TimeTracking.get_events_by_activity_today(
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
          create: true,
          update: true
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
        TimeTracking.get_events_by_activity_today(
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
          resource_name: "Project",
          update: true
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          resource_name: "Group",
          update: true
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
             |> render_click() =~ "stop-current-activity-#{activity.id}"

      assert {:ok, []} =
               TimeTracking.get_events_by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
