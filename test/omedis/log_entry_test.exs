defmodule Omedis.LogEntryTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.LogEntry

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, activity} = create_activity(organisation, %{group_id: group.id, project_id: project.id})
    {:ok, user} = create_user()
    {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "LogEntry",
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

  describe "by_activity/1" do
    test "returns log entries for a specific activity", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, %{results: result}} =
        LogEntry.by_activity(%{activity_id: activity.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, %{results: []}} =
               LogEntry.by_activity(
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
               LogEntry.by_activity(%{activity_id: activity.id}, tenant: organisation)
    end

    test "returns an error if organisation is not provided", %{
      activity: activity,
      user: user
    } do
      assert {:error, %Ash.Error.Invalid{}} =
               LogEntry.by_activity(%{activity_id: activity.id}, actor: user)
    end
  end

  describe "by_activity_today/1" do
    test "returns log entries for a specific activity created today", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          created_at: DateTime.add(DateTime.utc_now(), -2, :day)
        })

      {:ok, result} =
        LogEntry.by_activity_today(
          %{activity_id: activity.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_activity_today(
                 %{activity_id: activity.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "by_organisation/1" do
    test "returns log entries for a specific organisation", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, another_organisation} = create_organisation()

      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(another_organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, result} =
        LogEntry.by_organisation(%{organisation_id: organisation.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_organisation(%{organisation_id: organisation.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "by_organisation_today/1" do
    test "returns log entries created today for the specific organisation", %{
      organisation: organisation,
      user: user,
      activity: activity
    } do
      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          created_at: DateTime.add(DateTime.utc_now(), -2, :day)
        })

      {:ok, result} =
        LogEntry.by_organisation_today(%{organisation_id: organisation.id},
          actor: user,
          tenant: organisation
        )

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_organisation_today(
                 %{organisation_id: organisation.id},
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "create/1" do
    test "organisation owner can create a log entry", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      attrs = %{
        activity_id: activity.id,
        user_id: owner.id
      }

      assert {:ok, log_entry} = LogEntry.create(attrs, actor: owner, tenant: organisation)
      assert log_entry.activity_id == activity.id
      assert log_entry.organisation_id == organisation.id
      assert log_entry.user_id == owner.id
    end

    test "authorized user can create a log entry", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      attrs = %{
        activity_id: activity.id,
        user_id: user.id
      }

      assert {:ok, log_entry} = LogEntry.create(attrs, actor: user, tenant: organisation)
      assert log_entry.activity_id == activity.id
      assert log_entry.organisation_id == organisation.id
      assert log_entry.user_id == user.id
    end

    test "unauthorized user cannot create a log entry", %{
      activity: activity,
      organisation: organisation
    } do
      {:ok, unauthorized_user} = create_user()

      attrs = %{
        activity_id: activity.id,
        user_id: unauthorized_user.id
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.create(attrs, actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "read/1" do
    test "organisation owner can read all log entries", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, result} = LogEntry.read(actor: user, tenant: organisation)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "authorized user can read all log entries", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, another_user} = create_user()

      {:ok, log_entry_1} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: another_user.id
        })

      {:ok, result} = LogEntry.read(actor: user, tenant: organisation)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "unauthorized user cannot read log entries", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id
        })

      {:ok, _} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: unauthorized_user.id
        })

      assert {:ok, []} = LogEntry.read(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "update/1" do
    test "organisation owner can update a log entry", %{
      activity: activity,
      organisation: organisation,
      owner: owner
    } do
      {:ok, log_entry} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: owner.id,
          comment: "Original comment"
        })

      update_attrs = %{comment: "Updated comment"}

      assert {:ok, updated_log_entry} =
               LogEntry.update(log_entry, update_attrs, actor: owner, tenant: organisation)

      assert updated_log_entry.comment == "Updated comment"
    end

    test "authorized user can update a log entry", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, log_entry} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          comment: "Original comment"
        })

      update_attrs = %{comment: "Updated comment"}

      assert {:ok, updated_log_entry} =
               LogEntry.update(log_entry, update_attrs, actor: user, tenant: organisation)

      assert updated_log_entry.comment == "Updated comment"
    end

    test "unauthorized user cannot update a log entry", %{
      activity: activity,
      organisation: organisation,
      user: user
    } do
      {:ok, log_entry} =
        create_log_entry(organisation, %{
          activity_id: activity.id,
          user_id: user.id,
          comment: "Original comment"
        })

      {:ok, unauthorized_user} = create_user()

      update_attrs = %{comment: "Updated comment"}

      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.update(log_entry, update_attrs,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
