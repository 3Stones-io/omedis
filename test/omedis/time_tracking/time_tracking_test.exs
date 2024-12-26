defmodule Omedis.TimeTrackingTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.TimeTracking
  alias Omedis.TimeTracking.Activity

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, authorized_user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Activity",
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        update: true
      })

    {:ok, user} = create_user()
    {:ok, group_2} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{group_id: group_2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group_2.id,
        read: true,
        resource_name: "Organisation",
        update: true
      })

    %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project,
      authorized_user: authorized_user,
      user: user
    }
  end

  describe "move_activity_up/2" do
    setup %{group: group, organisation: organisation, project: project} do
      {:ok, activity1} =
        create_activity(organisation, %{
          name: "Activity 1",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0001",
          slug: "activity-1"
        })

      {:ok, activity2} =
        create_activity(organisation, %{
          name: "Activity 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002",
          slug: "activity-2"
        })

      %{activity1: activity1, activity2: activity2}
    end

    test "organisation owner can move an activity up in position", %{
      activity1: activity1,
      activity2: activity2,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, moved_activity} =
               TimeTracking.move_activity_up(activity2, actor: owner, tenant: organisation)

      assert moved_activity.position == 1

      {:ok, updated_activity1} = Activity.by_id(activity1.id, actor: owner, tenant: organisation)
      assert updated_activity1.position == 2
    end

    test "authorized user can move an activity up in position", %{
      authorized_user: authorized_user,
      activity1: activity1,
      activity2: activity2,
      organisation: organisation
    } do
      assert {:ok, moved_activity} =
               TimeTracking.move_activity_up(activity2,
                 actor: authorized_user,
                 tenant: organisation
               )

      assert moved_activity.position == 1

      {:ok, updated_activity1} =
        Activity.by_id(activity1.id, actor: authorized_user, tenant: organisation)

      assert updated_activity1.position == 2
    end

    test "unauthorized user cannot move an activity up in position", %{
      activity2: activity2,
      organisation: organisation,
      user: user
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.move_activity_up(activity2, actor: user, tenant: organisation)
    end

    test "does nothing when activity is at top position", %{
      activity1: activity1,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, unchanged_activity} =
               TimeTracking.move_activity_up(activity1, actor: owner, tenant: organisation)

      assert unchanged_activity.position == 1
    end
  end

  describe "move_activity_down/2" do
    setup %{group: group, organisation: organisation, project: project} do
      {:ok, activity2} =
        create_activity(organisation, %{
          name: "Activity 1",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0001",
          slug: "activity-1"
        })

      {:ok, activity1} =
        create_activity(organisation, %{
          name: "Activity 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002",
          slug: "activity-2"
        })

      %{activity1: activity1, activity2: activity2}
    end

    test "organisation owner can move an activity down in position", %{
      activity1: activity1,
      activity2: activity2,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, moved_activity} =
               TimeTracking.move_activity_down(activity2, actor: owner, tenant: organisation)

      assert moved_activity.position == 2

      {:ok, updated_activity1} =
        Activity.by_id(activity1.id, actor: owner, tenant: organisation)

      assert updated_activity1.position == 1
    end

    test "authorized user can move an activity down in position", %{
      authorized_user: authorized_user,
      activity1: activity1,
      activity2: activity2,
      organisation: organisation
    } do
      assert {:ok, moved_activity} =
               TimeTracking.move_activity_down(activity2,
                 actor: authorized_user,
                 tenant: organisation
               )

      assert moved_activity.position == 2

      {:ok, updated_activity1} =
        Activity.by_id(activity1.id, actor: authorized_user, tenant: organisation)

      assert updated_activity1.position == 1
    end

    test "unauthorized user cannot move an activity down in position", %{
      activity2: activity2,
      organisation: organisation,
      user: user
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.move_activity_down(activity2, actor: user, tenant: organisation)
    end

    test "does nothing when activity is at bottom position", %{
      activity1: activity1,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, unchanged_activity} =
               TimeTracking.move_activity_down(activity1, actor: owner, tenant: organisation)

      assert unchanged_activity.position == 2
    end
  end

  describe "select_unused_color_code/1" do
    test "returns a unused color code for an activity", %{
      organisation: organisation
    } do
      {:ok, activity} = create_activity(organisation, %{color_code: "#1f77b4"})
      assert TimeTracking.select_unused_color_code(organisation) != activity.color_code
    end
  end
end
