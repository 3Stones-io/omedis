defmodule Omedis.LogEntryTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.LogEntry

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: tenant.id})
    {:ok, project} = create_project(%{organisation_id: tenant.id})
    {:ok, log_category} = create_log_category(%{group_id: group.id, project_id: project.id})
    {:ok, user} = create_user()
    {:ok, _} = create_group_user(%{group_id: group.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogEntry",
        organisation_id: tenant.id,
        write: true
      })

    %{
      owner: owner,
      tenant: tenant,
      group: group,
      log_category: log_category,
      user: user
    }
  end

  describe "by_log_category/1" do
    test "returns log entries for a specific log category", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, %{results: result}} =
        LogEntry.by_log_category(%{log_category_id: log_category.id}, actor: user, tenant: tenant)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "returns an empty list for unauthorized user", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, %{results: []}} =
               LogEntry.by_log_category(
                 %{log_category_id: log_category.id},
                 actor: unauthorized_user,
                 tenant: tenant
               )
    end

    test "returns an error if actor is not provided", %{
      log_category: log_category,
      tenant: tenant
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.by_log_category(%{log_category_id: log_category.id}, tenant: tenant)
    end

    test "returns an error if tenant is not provided", %{
      log_category: log_category,
      user: user
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.by_log_category(%{log_category_id: log_category.id}, actor: user)
    end
  end

  describe "by_log_category_today/1" do
    test "returns log entries for a specific log category created today", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id,
          created_at: DateTime.add(DateTime.utc_now(), -2, :day)
        })

      {:ok, result} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: user,
          tenant: tenant
        )

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_log_category_today(
                 %{log_category_id: log_category.id},
                 actor: unauthorized_user,
                 tenant: tenant
               )
    end
  end

  describe "by_tenant/1" do
    test "returns log entries for a specific tenant", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, another_tenant} = create_tenant()

      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: another_tenant.id,
          user_id: user.id
        })

      {:ok, result} =
        LogEntry.by_tenant(%{organisation_id: tenant.id}, actor: user, tenant: tenant)

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_tenant(%{organisation_id: tenant.id},
                 actor: unauthorized_user,
                 tenant: tenant
               )
    end
  end

  describe "by_tenant_today/1" do
    test "returns log entries created today for the specific tenant", %{
      tenant: tenant,
      user: user,
      log_category: log_category
    } do
      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, _log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id,
          created_at: DateTime.add(DateTime.utc_now(), -2, :day)
        })

      {:ok, result} =
        LogEntry.by_tenant_today(%{organisation_id: tenant.id}, actor: user, tenant: tenant)

      assert length(result) == 1
      assert hd(result).id == log_entry_1.id
    end

    test "returns an empty list for unauthorized user", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               LogEntry.by_tenant_today(
                 %{organisation_id: tenant.id},
                 actor: unauthorized_user,
                 tenant: tenant
               )
    end
  end

  describe "create/1" do
    test "tenant owner can create a log entry", %{
      log_category: log_category,
      tenant: tenant,
      owner: owner
    } do
      attrs = %{
        log_category_id: log_category.id,
        organisation_id: tenant.id,
        user_id: owner.id
      }

      assert {:ok, log_entry} = LogEntry.create(attrs, actor: owner, tenant: tenant)
      assert log_entry.log_category_id == log_category.id
      assert log_entry.tenant_id == tenant.id
      assert log_entry.user_id == owner.id
    end

    test "authorized user can create a log entry", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      attrs = %{
        log_category_id: log_category.id,
        organisation_id: tenant.id,
        user_id: user.id
      }

      assert {:ok, log_entry} = LogEntry.create(attrs, actor: user, tenant: tenant)
      assert log_entry.log_category_id == log_category.id
      assert log_entry.tenant_id == tenant.id
      assert log_entry.user_id == user.id
    end

    test "unauthorized user cannot create a log entry", %{
      log_category: log_category,
      tenant: tenant
    } do
      {:ok, unauthorized_user} = create_user()

      attrs = %{
        log_category_id: log_category.id,
        organisation_id: tenant.id,
        user_id: unauthorized_user.id
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.create(attrs, actor: unauthorized_user, tenant: tenant)
    end
  end

  describe "read/1" do
    test "tenant owner can read all log entries", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, result} = LogEntry.read(actor: user, tenant: tenant)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "authorized user can read all log entries", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, another_user} = create_user()

      {:ok, log_entry_1} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, log_entry_2} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: another_user.id
        })

      {:ok, result} = LogEntry.read(actor: user, tenant: tenant)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [log_entry_1.id, log_entry_2.id]
    end

    test "unauthorized user cannot read log entries", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: unauthorized_user.id
        })

      assert {:ok, []} = LogEntry.read(actor: unauthorized_user, tenant: tenant)
    end
  end

  describe "update/1" do
    test "tenant owner can update a log entry", %{
      log_category: log_category,
      tenant: tenant,
      owner: owner
    } do
      {:ok, log_entry} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: owner.id,
          comment: "Original comment"
        })

      update_attrs = %{comment: "Updated comment"}

      assert {:ok, updated_log_entry} =
               LogEntry.update(log_entry, update_attrs, actor: owner, tenant: tenant)

      assert updated_log_entry.comment == "Updated comment"
    end

    test "authorized user can update a log entry", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, log_entry} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id,
          comment: "Original comment"
        })

      update_attrs = %{comment: "Updated comment"}

      assert {:ok, updated_log_entry} =
               LogEntry.update(log_entry, update_attrs, actor: user, tenant: tenant)

      assert updated_log_entry.comment == "Updated comment"
    end

    test "unauthorized user cannot update a log entry", %{
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, log_entry} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: tenant.id,
          user_id: user.id,
          comment: "Original comment"
        })

      {:ok, unauthorized_user} = create_user()

      update_attrs = %{comment: "Updated comment"}

      assert {:error, %Ash.Error.Forbidden{}} =
               LogEntry.update(log_entry, update_attrs, actor: unauthorized_user, tenant: tenant)
    end
  end
end
