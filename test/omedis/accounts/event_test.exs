defmodule Omedis.EventTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Event

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id}, actor: owner)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, activity} = create_activity(organisation, %{group_id: group.id, project_id: project.id})
    {:ok, user} = create_user()
    {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Event",
        create: true,
        update: true
      })

    %{
      owner: owner,
      organisation: organisation,
      group: group,
      activity: activity,
      user: user
    }
  end

  describe "by_activity/2" do
    test "returns events for a specific activity", %{
      activity: activity,
      organisation: organisation,
      user: user
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
        Event.by_activity(%{activity_id: activity.id},
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
               Event.by_activity(
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
               Event.by_activity(%{activity_id: activity.id}, tenant: organisation)
    end

    test "returns an error if organisation is not provided", %{
      activity: activity,
      user: user
    } do
      assert {:error, %Ash.Error.Invalid{}} =
               Event.by_activity(%{activity_id: activity.id}, actor: user)
    end
  end

  describe "by_activity_today/2" do
    test "returns events for a specific activity created today", %{
      activity: activity,
      organisation: organisation,
      user: user
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
        Event.by_activity_today(
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
               Event.by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "create/2" do
    test "organisation owner can create an event", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, owner.id)

      assert {:ok, event} = Event.create(attrs, actor: owner, tenant: organisation)
      assert event.activity_id == activity.id
      assert event.organisation_id == organisation.id
      assert event.user_id == owner.id
    end

    test "authorized user can create an event", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)

      assert {:ok, event} = Event.create(attrs, actor: user, tenant: organisation)
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
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:summary, 1)
        |> Map.put(:user_id, user.id)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.create(attrs, actor: user, tenant: organisation)

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
               Event.create(%{}, actor: user, tenant: organisation)

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
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, get_datetime_after(-1, :minute))

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.create(attrs, actor: user, tenant: organisation)

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
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, unauthorized_user.id)

      assert {:error, %Ash.Error.Forbidden{}} =
               Event.create(attrs, actor: unauthorized_user, tenant: organisation)
    end

    test "allows overlapping events for different users", %{
      activity: activity,
      organisation: organisation,
      owner: owner,
      user: authorized_user
    } do
      # Create an event for organisation owner
      now = DateTime.utc_now()
      one_hour_later = get_datetime_after(3600, :second)

      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, owner.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, one_hour_later)

      assert {:ok, _} = Event.create(attrs, actor: owner, tenant: organisation)

      # Create overlapping event for the authorized user
      other_attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, authorized_user.id)
        # 30 minutes after start
        |> Map.put(:dtstart, get_datetime_after(1800, :second))
        # 90 minutes after start
        |> Map.put(:dtend, get_datetime_after(5400, :second))

      assert {:ok, _} =
               Event.create(other_attrs, actor: authorized_user, tenant: organisation)
    end

    test "prevents creating an event that starts before an ongoing event ends", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      now = DateTime.utc_now()
      one_hour_later = get_datetime_after(3600, :second)

      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, one_hour_later)

      assert {:ok, _} = Event.create(attrs, actor: user, tenant: organisation)

      # Try to create overlapping event - starts during first event
      overlapping_event_attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 1 minute after start
        |> Map.put(:dtstart, get_datetime_after(60, :second))

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.create(overlapping_event_attrs, actor: user, tenant: organisation)

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
      user: user
    } do
      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, nil)

      assert {:ok, _} = Event.create(attrs, actor: user, tenant: organisation)

      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 1 minute after start
        |> Map.put(:dtstart, DateTime.utc_now())

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.create(attrs, actor: user, tenant: organisation)

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
           user: user
         } do
      after_one_second = get_datetime_after(1, :second)

      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtend, after_one_second)

      assert {:ok, _} = Event.create(attrs, actor: user, tenant: organisation)

      attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # Same time as end of ongoing event
        |> Map.put(:dtstart, after_one_second)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.create(attrs, actor: user, tenant: organisation)

      assert [
               %Ash.Error.Changes.InvalidAttribute{
                 field: :dtstart,
                 message: "cannot create an event that overlaps with another event"
               }
             ] = errors
    end
  end

  describe "list_paginated/1" do
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
               Event.list_paginated(
                 page: [limit: 10, offset: 0],
                 actor: owner,
                 tenant: organisation
               )

      assert length(results) == 10
      assert count == 15

      # Fetch second page of paginated events
      assert {:ok, %{results: results}} =
               Event.list_paginated(
                 page: [limit: 10, offset: 10],
                 actor: owner,
                 tenant: organisation
               )

      assert length(results) == 5
    end

    test "returns paginated events for authorized user", %{
      activity: activity,
      organisation: organisation,
      user: authorized_user
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
               Event.list_paginated(
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
               Event.list_paginated(
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
               Event.list_paginated(
                 page: [limit: 10, offset: 0],
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "returns an error if actor is not provided", %{
      organisation: organisation
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               Event.list_paginated(
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )
    end
  end

  describe "list_paginated_today/1" do
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
               Event.list_paginated_today(
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
      user: authorized_user
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
               Event.list_paginated_today(
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
               Event.list_paginated_today(
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
               Event.list_paginated_today(
                 page: [limit: 10, offset: 0],
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "returns an error if actor is not provided", %{
      organisation: organisation
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               Event.list_paginated_today(
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )
    end
  end

  describe "read/1" do
    test "organisation owner can read all events", %{
      activity: activity,
      organisation: organisation,
      user: user
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

      {:ok, [event_1_from_db, event_2_from_db]} = Event.read(actor: user, tenant: organisation)

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
      user: user
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

      {:ok, result} = Event.read(actor: user, tenant: organisation)

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

      assert {:ok, []} = Event.read(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "update/2" do
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
               Event.update(event, update_attrs, actor: owner, tenant: organisation)

      assert updated_event.summary == "Updated summary"
    end

    test "authorized user can update an event", %{
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

      update_attrs = %{summary: "Updated summary"}

      assert {:ok, updated_event} =
               Event.update(event, update_attrs, actor: user, tenant: organisation)

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
               Event.update(event, update_attrs,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end

    test "prevents updates that would create overlaps", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      # Create two non-overlapping events
      now = DateTime.utc_now()

      first_attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        |> Map.put(:dtstart, now)
        |> Map.put(:dtend, get_datetime_after(3600, :second))

      second_attrs =
        Event
        |> attrs_for(organisation)
        |> Map.put(:activity_id, activity.id)
        |> Map.put(:user_id, user.id)
        # 2 hours after start
        |> Map.put(:dtstart, get_datetime_after(7200, :second))
        # 3 hours after start
        |> Map.put(:dtend, get_datetime_after(10_800, :second))

      assert {:ok, _first_event} = Event.create(first_attrs, actor: user, tenant: organisation)
      assert {:ok, second_event} = Event.create(second_attrs, actor: user, tenant: organisation)

      # Try to update second event to overlap with first
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Event.update(
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
