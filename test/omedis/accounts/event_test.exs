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
        write: true
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
      {:ok, event_1} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, event_2} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

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
      {:ok, _} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

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
      {:ok, event_1} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _event_2} =
        create_event(
          organisation,
          %{
            activity_id: activity.id,
            user_id: user.id
          },
          context: %{created_at: DateTime.add(DateTime.utc_now(), -2, :day)}
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
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

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
        |> Map.put(:dtend, DateTime.add(DateTime.utc_now(), -1, :minute))

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
  end

  describe "read/1" do
    test "organisation owner can read all events", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, event_1} =
        create_event(organisation, %{
          activity_id: activity.id,
          dtend: DateTime.add(DateTime.utc_now(), 60, :minute),
          dtstart: DateTime.utc_now(),
          user_id: user.id
        })

      {:ok, event_2} =
        create_event(organisation, %{
          activity_id: activity.id,
          dtend: nil,
          user_id: user.id
        })

      {:ok, [event_1_from_db, event_2_from_db]} = Event.read(actor: user, tenant: organisation)

      date_time_now = DateTime.utc_now() |> DateTime.truncate(:second)

      assert event_1_from_db.id == event_1.id
      assert event_2_from_db.id == event_2.id
      assert event_1_from_db.uid == event_1.id
      assert event_2_from_db.uid == event_2.id
      assert DateTime.truncate(event_1_from_db.dtstamp, :second) == date_time_now
      assert DateTime.truncate(event_2_from_db.dtstamp, :second) == date_time_now
      assert event_1_from_db.duration_minutes == 60
      assert event_2_from_db.duration_minutes == nil
    end

    test "authorized user can read all events", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, another_user} = create_user()

      {:ok, event_1} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, event_2} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: another_user.id
        })

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
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _} =
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: unauthorized_user.id
        })

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
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: owner.id,
          summary: "Original summary"
        })

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
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          summary: "Original summary"
        })

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
        create_event(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          summary: "Original summary"
        })

      {:ok, unauthorized_user} = create_user()

      update_attrs = %{summary: "Updated summary"}

      assert {:error, %Ash.Error.Forbidden{}} =
               Event.update(event, update_attrs,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
