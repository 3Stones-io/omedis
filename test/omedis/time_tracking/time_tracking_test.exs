defmodule Omedis.TimeTrackingTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.TimeTracking

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()
    {:ok, group_2} = create_group(organisation)

    # Create group memberships
    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} = create_group_membership(organisation, %{group_id: group_2.id, user_id: user.id})

    # Create access rights for Activity resource
    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        create: true,
        resource_name: "Activity",
        update: true
      })

    # Create access rights for Event resource
    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Event",
        create: true,
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group_2.id,
        read: true,
        resource_name: "Organisation",
        update: true
      })

    %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      owner: owner,
      project: project,
      user: user
    }
  end

  defp setup_activity(%{
         group: group,
         organisation: organisation,
         project: project
       }) do
    {:ok, activity} =
      create_activity(organisation, %{group_id: group.id, project_id: project.id})

    %{activity: activity}
  end

  describe "create_activity/2" do
    test "organisation owner can create an activity", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000"
      }

      assert {:ok, activity} =
               TimeTracking.create_activity(attrs, actor: owner, tenant: organisation)

      assert activity.name == "Test Activity"
      assert activity.color_code == "#FF0000"
      assert activity.position == 1
    end

    test "authorized user can create an activity", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000"
      }

      assert {:ok, activity} =
               TimeTracking.create_activity(attrs, actor: authorized_user, tenant: organisation)

      assert activity.name == "Test Activity"
    end

    test "unauthorized user cannot create an activity", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000"
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.create_activity(attrs, actor: user, tenant: organisation)
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        group_id: group.id,
        project_id: project.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               TimeTracking.create_activity(attrs, actor: owner, tenant: organisation)
    end
  end

  describe "update_activity/2" do
    test "organisation owner can update an activity", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:ok, updated_activity} =
               TimeTracking.update_activity(activity, %{name: "Updated Activity"},
                 actor: owner,
                 tenant: organisation
               )

      assert updated_activity.name == "Updated Activity"
    end

    test "authorized user can update an activity", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:ok, updated_activity} =
               TimeTracking.update_activity(activity, %{name: "Updated Activity"},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert updated_activity.name == "Updated Activity"
    end

    test "unauthorized user cannot update an activity", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.update_activity(activity, %{name: "Updated Activity"},
                 actor: user,
                 tenant: organisation
               )
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      invalid_attrs = %{
        name: "",
        color_code: "invalid-color"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               TimeTracking.update_activity(activity, invalid_attrs,
                 actor: owner,
                 tenant: organisation
               )
    end
  end

  describe "get_activity_by_id/2" do
    test "returns activity for organisation owner", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:ok, found_activity} =
               TimeTracking.get_activity_by_id(activity.id, actor: owner, tenant: organisation)

      assert found_activity.id == activity.id
    end

    test "returns activity for authorized user", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:ok, found_activity} =
               TimeTracking.get_activity_by_id(activity.id,
                 actor: authorized_user,
                 tenant: organisation
               )

      assert found_activity.id == activity.id
    end

    test "returns error for unauthorized user", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000"
        })

      assert {:error, %Ash.Error.Query.NotFound{}} =
               TimeTracking.get_activity_by_id(activity.id, actor: user, tenant: organisation)
    end
  end

  describe "list_paginated_activities/1" do
    setup %{group: group, organisation: organisation} do
      Enum.each(1..15, fn _ ->
        {:ok, _} =
          create_activity(organisation, %{
            group_id: group.id
          })
      end)

      :ok
    end

    test "returns paginated activities for organisation owner", %{
      group: group,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, paginated_result} =
               TimeTracking.list_paginated_activities(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: owner,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "returns paginated activities for authorized user", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation
    } do
      assert {:ok, paginated_result} =
               TimeTracking.list_paginated_activities(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "does not return paginated activities for unauthorized user", %{
      group: group,
      organisation: organisation,
      user: user
    } do
      assert {:ok, paginated_result} =
               TimeTracking.list_paginated_activities(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(paginated_result.results)
    end
  end

  describe "by_group_id_and_project_id/2" do
    setup %{group: group, organisation: organisation, project: project} do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id
        })

      %{activity: activity}
    end

    test "returns activities for specific group and project for organisation owner", %{
      activity: activity,
      group: group,
      owner: owner,
      project: project,
      organisation: organisation
    } do
      assert {:ok, activities} =
               TimeTracking.get_activities_by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: owner,
                 tenant: organisation
               )

      assert length(activities) == 1
      assert hd(activities).id == activity.id
    end

    test "returns activities for specific group and project for an authorized user", %{
      authorized_user: authorized_user,
      activity: activity,
      group: group,
      project: project,
      organisation: organisation
    } do
      assert {:ok, activities} =
               TimeTracking.get_activities_by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(activities) == 1
      assert hd(activities).id == activity.id
    end

    test "does not return activities for specific group and project for an unauthorized user",
         %{
           group: group,
           project: project,
           organisation: organisation,
           user: user
         } do
      assert {:ok, activities} =
               TimeTracking.get_activities_by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(activities)
    end
  end

  describe "set_default_activity" do
    setup %{group: group, organisation: organisation, project: project, owner: owner} do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          is_default: true
        })

      %{
        activity: activity,
        group: group,
        organisation: organisation,
        owner: owner,
        project: project
      }
    end

    test "a new activity can be set to default and the existing default is removed", %{
      activity: activity,
      group: group,
      organisation: organisation,
      owner: owner,
      project: project
    } do
      attrs = %{
        color_code: "#FF0000",
        group_id: group.id,
        is_default: true,
        name: "New Default Activity",
        project_id: project.id
      }

      assert {:ok, new_activity} =
               TimeTracking.create_activity(attrs, actor: owner, tenant: organisation)

      assert new_activity.is_default

      updated_older_default_activity =
        Ash.get!(TimeTracking.Activity, activity.id, actor: owner, tenant: organisation)

      refute updated_older_default_activity.is_default
    end

    test "can update default activity for existing records", %{
      activity: activity,
      group: group,
      organisation: organisation,
      owner: owner,
      project: project
    } do
      {:ok, activity_2} =
        create_activity(organisation, %{
          name: "Test Activity 2",
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, updated_activity} =
               TimeTracking.update_activity(activity_2, %{is_default: true},
                 actor: owner,
                 tenant: organisation
               )

      assert updated_activity.is_default

      updated_older_default_activity =
        Ash.get!(TimeTracking.Activity, activity.id, actor: owner, tenant: organisation)

      refute updated_older_default_activity.is_default
    end
  end

  describe "move_activity_up/2" do
    setup %{group: group, organisation: organisation, project: project} do
      {:ok, activity1} =
        create_activity(organisation, %{
          name: "Activity 1",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0001"
        })

      {:ok, activity2} =
        create_activity(organisation, %{
          name: "Activity 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002"
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

      {:ok, updated_activity1} =
        TimeTracking.get_activity_by_id(activity1.id, actor: owner, tenant: organisation)

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
        TimeTracking.get_activity_by_id(activity1.id,
          actor: authorized_user,
          tenant: organisation
        )

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
          color_code: "#FF0001"
        })

      {:ok, activity1} =
        create_activity(organisation, %{
          name: "Activity 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002"
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
        TimeTracking.get_activity_by_id(activity1.id, actor: owner, tenant: organisation)

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
        TimeTracking.get_activity_by_id(activity1.id,
          actor: authorized_user,
          tenant: organisation
        )

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

  ## Events tests
  describe "get_events_by_activity/2" do
    setup [:setup_activity]

    test "returns events for a specific activity", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      after_one_second = get_datetime_after(1, :second)

      {:ok, event_1} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: user.id
          },
          actor: user
        )

      after_two_seconds = get_datetime_after(2, :second)

      {:ok, event_2} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_two_seconds,
            user_id: user.id
          },
          actor: user
        )

      {:ok, %{results: result}} =
        TimeTracking.get_events_by_activity(%{activity_id: activity.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [event_1.id, event_2.id]
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      after_one_second = get_datetime_after(1, :second)

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: user.id
          },
          actor: user
        )

      after_two_second = get_datetime_after(2, :second)

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_two_second,
            user_id: user.id
          },
          actor: user
        )

      {:ok, unauthorized_user} = create_user()

      assert {:ok, %{results: []}} =
               TimeTracking.get_events_by_activity(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "returns an error if actor is not provided", %{
      activity: activity,
      organisation: organisation
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.get_events_by_activity(%{activity_id: activity.id},
                 tenant: organisation
               )
    end

    test "returns an error if organisation is not provided", %{
      activity: activity,
      user: user
    } do
      assert {:error, %Ash.Error.Invalid{}} =
               TimeTracking.get_events_by_activity(%{activity_id: activity.id}, actor: user)
    end
  end

  describe "get_events_by_activity_today/2" do
    setup [:setup_activity]

    test "returns events for a specific activity created today", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      after_one_second = get_datetime_after(1, :second)

      {:ok, event_1} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: user.id
          },
          actor: user
        )

      after_two_seconds = get_datetime_after(2, :second)

      {:ok, _event_2} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_two_seconds,
            user_id: user.id
          },
          actor: user,
          context: %{created_at: get_datetime_after(-2, :day)}
        )

      {:ok, result} =
        TimeTracking.get_events_by_activity_today(
          %{activity_id: activity.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 1
      assert hd(result).id == event_1.id
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id
          },
          actor: user
        )

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               TimeTracking.get_events_by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "create_event/2" do
    setup [:setup_activity]

    test "organisation owner can create an event", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, owner.id)

      assert {:ok, event} = TimeTracking.create_event(attrs, actor: owner, tenant: organisation)
      assert event.activity_id == activity.id
      assert event.organisation_id == organisation.id
      assert event.user_id == owner.id
    end

    test "authorized user can create an event", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)

      assert {:ok, event} = TimeTracking.create_event(attrs, actor: user, tenant: organisation)
      assert event.activity_id == activity.id
      assert event.organisation_id == organisation.id
      assert event.user_id == user.id
    end

    test "returns an error when attributes are invalid", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:summary, 1)
        |> Map.put(:user_id, user.id)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :summary,
                 message: "is invalid"
               }
             ] = errors
    end

    test "returns an error when required params are missing", %{
      organisation: organisation,
      user: user
    } do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(%{}, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.Required{field: :activity_id},
               %Ash.Error.Changes.Required{field: :dtstart},
               %Ash.Error.Changes.Required{field: :summary},
               %Ash.Error.Changes.Required{field: :user_id}
             ] = errors
    end

    test "returns an error when end date is before start date", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, get_datetime_after(-1, :minute))

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtend,
                 message: "end date must be greater than the start date"
               }
             ] = errors
    end

    test "unauthorized user cannot create an event", %{
      activity: activity,
      organisation: organisation
    } do
      {:ok, unauthorized_user} = create_user()

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, unauthorized_user.id)

      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.create_event(attrs, actor: unauthorized_user, tenant: organisation)
    end

    test "allows overlapping events for different users", %{
      activity: activity,
      organisation: organisation,
      owner: owner,
      authorized_user: authorized_user
    } do
      # Create an event for organisation owner
      now = DateTime.utc_now()
      one_hour_later = get_datetime_after(3600, :second)

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, owner.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, one_hour_later)

      assert {:ok, _} = TimeTracking.create_event(attrs, actor: owner, tenant: organisation)

      # Create overlapping event for the authorized user
      other_attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, authorized_user.id)
        # 30 minutes after start
        |> Map.put(:dtstart, get_datetime_after(1800, :second))
        # 90 minutes after start
        |> Map.put(:dtend, get_datetime_after(5400, :second))

      assert {:ok, _} =
               TimeTracking.create_event(other_attrs,
                 actor: authorized_user,
                 tenant: organisation
               )
    end

    test "prevents creating an event that starts before an ongoing event ends", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      now = DateTime.utc_now()
      one_hour_later = get_datetime_after(3600, :second)

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, one_hour_later)

      assert {:ok, _} = TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      # Try to create overlapping event - starts during first event
      overlapping_event_attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 1 minute after start
        |> Map.put(:dtstart, get_datetime_after(60, :second))

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(overlapping_event_attrs,
                 actor: user,
                 tenant: organisation
               )

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtstart,
                 message: "cannot create an event that overlaps with another event"
               }
             ] = errors
    end

    test "prevents creating an event that overlaps with ongoing events", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, nil)

      assert {:ok, _} = TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 1 minute after start
        |> Map.put(:dtstart, DateTime.utc_now())

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtstart,
                 message: "cannot create an event that overlaps with another event"
               }
             ] = errors
    end

    test "prevents creating an event that starts at the same time as end time of an ongoing event",
         %{
           activity: activity,
           organisation: organisation,
           owner: user
         } do
      after_one_second = get_datetime_after(1, :second)

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, after_one_second)

      assert {:ok, _} = TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # Same time as end of ongoing event
        |> Map.put(:dtstart, after_one_second)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.create_event(attrs, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtstart,
                 message: "cannot create an event that overlaps with another event"
               }
             ] = errors
    end
  end

  describe "list_paginated_events/1" do
    setup [:setup_activity]

    test "returns paginated events for organisation owner", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      for i <- 1..15 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, _} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: owner.id
            },
            actor: owner
          )
      end

      # Fetch first page of paginated events
      assert {:ok, %{results: results, count: count}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: owner,
                 tenant: organisation
               )

      assert length(results) == 10
      assert count == 15

      # Fetch second page of paginated events
      assert {:ok, %{results: results}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 10],
                 actor: owner,
                 tenant: organisation
               )

      assert length(results) == 5
    end

    test "returns paginated events for authorized user", %{
      activity: activity,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      for i <- 1..15 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, _} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: authorized_user.id
            },
            actor: authorized_user
          )
      end

      # Fetch paginated events
      assert {:ok, %{results: results, count: count}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(results) == 10
      assert count == 15
    end

    test "sorts events by created_at attribute", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      for i <- 1..3 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, event} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: owner.id
            },
            actor: owner,
            context: %{created_at: Omedis.TestUtils.time_after(-i * 12_000)}
          )

        event
      end

      assert {:ok, %{results: events}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: owner,
                 tenant: organisation
               )

      created_at_timestamps = Enum.map(events, & &1.created_at)
      assert created_at_timestamps == Enum.sort(created_at_timestamps, {:asc, DateTime})
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: authorized_user.id
          },
          actor: authorized_user
        )

      {:ok, unauthorized_user} = create_user()

      assert {:ok, %{results: [], count: 0}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "returns an error if actor is not provided", %{
      organisation: organisation
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.list_paginated_events(
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )
    end
  end

  describe "list_today_paginated_events/1" do
    setup [:setup_activity]

    test "returns today's paginated events for organisation owner", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      past_date = get_datetime_after(-2, :day)

      {:ok, past_event} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: get_datetime_after(-1, :day),
            dtstart: past_date,
            user_id: owner.id
          },
          actor: owner,
          context: %{created_at: past_date}
        )

      for i <- 1..5 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, _today_event} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: owner.id
            },
            actor: owner
          )
      end

      assert {:ok, %{results: results, count: count}} =
               TimeTracking.list_today_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: owner,
                 tenant: organisation
               )

      assert length(results) == 5
      assert count == 5

      refute Enum.any?(results, fn event ->
               DateTime.diff(event.created_at, DateTime.utc_now(), :day) > 0
             end)

      refute Enum.any?(results, fn event ->
               event.id == past_event.id
             end)
    end

    test "returns today's paginated events for authorized user", %{
      activity: activity,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      past_date = get_datetime_after(-2, :day)

      {:ok, past_event} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: get_datetime_after(-1, :day),
            dtstart: past_date,
            user_id: authorized_user.id
          },
          actor: authorized_user,
          context: %{created_at: past_date}
        )

      for i <- 1..5 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, _today_event} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: authorized_user.id
            },
            actor: authorized_user
          )
      end

      assert {:ok, %{results: results, count: count}} =
               TimeTracking.list_today_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(results) == 5
      assert count == 5

      refute Enum.any?(results, fn event ->
               DateTime.diff(event.created_at, DateTime.utc_now(), :day) > 0
             end)

      refute Enum.any?(results, fn event ->
               event.id == past_event.id
             end)
    end

    test "sorts today's events by created_at attribute", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      for i <- 1..3 do
        dtstart = get_datetime_after(i + 1, :second)
        dtend = get_datetime_after(i + 2, :second)

        {:ok, event} =
          create_event(
            organisation,
            %{
              activity_id: activity.id,
              dtend: dtend,
              dtstart: dtstart,
              user_id: owner.id
            },
            actor: owner,
            context: %{created_at: Omedis.TestUtils.time_after(-i * 3600)}
          )

        event
      end

      assert {:ok, %{results: results}} =
               TimeTracking.list_today_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: owner,
                 tenant: organisation
               )

      created_at_timestamps = Enum.map(results, & &1.created_at)
      assert created_at_timestamps == Enum.sort(created_at_timestamps, {:asc, DateTime})
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: authorized_user
    } do
      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: authorized_user.id
          },
          actor: authorized_user
        )

      {:ok, unauthorized_user} = create_user()

      assert {:ok, %{results: [], count: 0}} =
               TimeTracking.list_today_paginated_events(
                 page: [limit: 10, offset: 0],
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "returns an error if actor is not provided", %{
      organisation: organisation
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.list_today_paginated_events(
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )
    end
  end

  describe "list_events/1" do
    setup [:setup_activity]

    test "organisation owner can read all events", %{
      activity: activity,
      organisation: organisation,
      owner: user
    } do
      {:ok, event_1} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: get_datetime_after(60, :minute),
            dtstart: DateTime.utc_now(),
            user_id: user.id
          },
          actor: user
        )

      {:ok, event_2} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: get_datetime_after(61, :minute),
            dtend: nil,
            user_id: user.id
          },
          actor: user
        )

      {:ok, events_from_db} = TimeTracking.list_events(actor: user, tenant: organisation)

      assert length(events_from_db) == 2

      event_1_from_db = Enum.find(events_from_db, fn event -> event.id == event_1.id end)
      event_2_from_db = Enum.find(events_from_db, fn event -> event.id == event_2.id end)

      assert event_1_from_db.id == event_1.id
      assert event_2_from_db.id == event_2.id
      assert event_1_from_db.uid == event_1.id
      assert event_2_from_db.uid == event_2.id
      assert event_1_from_db.duration_minutes == 60
      assert event_2_from_db.duration_minutes == nil

      date_time_now = DateTime.utc_now()

      # Allow for small time differences by checking if timestamps are within 1 second
      assert_in_delta DateTime.to_unix(event_1_from_db.dtstamp),
                      DateTime.to_unix(date_time_now),
                      1

      assert_in_delta DateTime.to_unix(event_2_from_db.dtstamp),
                      DateTime.to_unix(date_time_now),
                      1
    end

    test "authorized user can read all events", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      after_one_second = get_datetime_after(1, :second)
      {:ok, another_user} = create_user()

      {:ok, event_1} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtend: after_one_second,
            user_id: user.id
          },
          actor: user
        )

      {:ok, event_2} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            dtstart: after_one_second,
            user_id: another_user.id
          },
          actor: another_user
        )

      {:ok, result} = TimeTracking.list_events(actor: user, tenant: organisation)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [event_1.id, event_2.id]
    end

    test "unauthorized user cannot read events", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id
          },
          actor: user
        )

      {:ok, _} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: unauthorized_user.id
          },
          actor: unauthorized_user
        )

      assert {:ok, []} = TimeTracking.list_events(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "update_event/2" do
    setup [:setup_activity]

    test "organisation owner can update an event", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      {:ok, event} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: owner.id,
            summary: "Original summary"
          },
          actor: owner
        )

      update_attrs = %{summary: "Updated summary"}

      assert {:ok, updated_event} =
               TimeTracking.update_event(event, update_attrs, actor: owner, tenant: organisation)

      assert updated_event.summary == "Updated summary"
    end

    test "authorized user can update an event", %{
      activity: activity,
      organisation: organisation,
      authorized_user: user
    } do
      {:ok, event} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id,
            summary: "Original summary"
          },
          actor: user
        )

      update_attrs = %{summary: "Updated summary"}

      assert {:ok, updated_event} =
               TimeTracking.update_event(event, update_attrs, actor: user, tenant: organisation)

      assert updated_event.summary == "Updated summary"
    end

    test "unauthorized user cannot update an event", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, event} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id,
            summary: "Original summary"
          },
          actor: user
        )

      {:ok, unauthorized_user} = create_user()

      update_attrs = %{summary: "Updated summary"}

      assert {:error, %Ash.Error.Forbidden{}} =
               TimeTracking.update_event(event, update_attrs,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "prevents updates that would create overlaps", %{
      activity: activity,
      organisation: organisation,
      owner: user
    } do
      # Create two non-overlapping events
      now = DateTime.utc_now()

      first_attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, get_datetime_after(3600, :second))

      second_attrs =
        TimeTracking.Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 2 hours after start
        |> Map.put(:dtstart, get_datetime_after(7200, :second))
        # 3 hours after start
        |> Map.put(:dtend, get_datetime_after(10_800, :second))

      assert {:ok, _first_event} =
               TimeTracking.create_event(first_attrs, actor: user, tenant: organisation)

      assert {:ok, second_event} =
               TimeTracking.create_event(second_attrs, actor: user, tenant: organisation)

      # Try to update second event to overlap with first
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               TimeTracking.update_event(
                 second_event,
                 # 30 minutes after start
                 %{dtstart: get_datetime_after(1800, :second)},
                 actor: user,
                 tenant: organisation
               )

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtstart,
                 message: "cannot create an event that overlaps with another event"
               }
             ] = errors
    end
  end

  defp get_datetime_after(offset, value) do
    DateTime.utc_now()
    |> DateTime.add(offset, value)
  end
end
