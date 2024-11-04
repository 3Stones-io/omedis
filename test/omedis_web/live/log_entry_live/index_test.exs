defmodule OmedisWeb.LogEntryLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})
    {:ok, log_category} = create_log_category(%{group_id: group.id, project_id: project.id})
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()
    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogEntry",
        tenant_id: tenant.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id
      })

    %{
      authorized_user: authorized_user,
      group: group,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: tenant,
      user: user
    }
  end

  describe "/tenants/:slug/log_categories/:id/log_entries" do
    test "tenant owner can see all log entries", %{
      conn: conn,
      tenant: tenant,
      log_category: log_category,
      owner: owner,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          tenant_id: tenant.id,
          user_id: user.id,
          comment: "User's log entry"
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          tenant_id: tenant.id,
          user_id: owner.id,
          comment: "Owner's log entry"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/log_categories/#{log_category.id}/log_entries")

      assert html =~ "User&#39;s log entry"
      assert html =~ "Owner&#39;s log entry"
    end

    test "authorized user can see all log entries", %{
      authorized_user: authorized_user,
      conn: conn,
      log_category: log_category,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          tenant_id: tenant.id,
          user_id: authorized_user.id,
          comment: "Test comment 1"
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          tenant_id: tenant.id,
          user_id: user.id,
          comment: "Test comment 2"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/log_categories/#{log_category.id}/log_entries")

      assert html =~ "Test comment 1"
      assert html =~ "Test comment 2"
    end

    test "unauthorized user cannot see log entries", %{
      conn: conn,
      group: group,
      log_category: log_category,
      user: user
    } do
      {:ok, another_user} = create_user()
      {:ok, tenant} = create_tenant(%{owner_id: another_user.id})
      {:ok, _} = create_group_user(%{group_id: group.id, user_id: user.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          read: true,
          resource_name: "Tenant",
          tenant_id: tenant.id
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          tenant_id: tenant.id,
          user_id: user.id,
          comment: "Test comment"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/log_categories/#{log_category.id}/log_entries")

      refute html =~ "Test comment"
    end
  end
end
