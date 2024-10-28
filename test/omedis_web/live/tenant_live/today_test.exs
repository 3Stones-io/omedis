defmodule OmedisWeb.TenantLive.TodayTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})

    {:ok, log_category} =
      create_log_category(%{group_id: group.id, is_default: true, project_id: project.id})

    {:ok, authorized_user} =
      create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})

    {:ok, user} = create_user(%{daily_start_at: ~T[08:00:00], daily_end_at: ~T[18:00:00]})

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

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

  describe "Today LiveView" do
    test "tenant owner can see log entries", %{
      conn: conn,
      group: group,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: tenant
    } do
      {:ok, _} =
        create_log_entry(%{
          comment: "Test comment",
          end_at: ~T[06:00:00],
          log_category_id: log_category.id,
          start_at: ~T[05:00:00],
          tenant_id: tenant.id,
          user_id: owner.id
        })

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      assert html =~ "Select group and project"
      assert html =~ "05:00"
      assert html =~ "06:00"
    end

    test "authorized user can see log entries", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      log_category: log_category,
      project: project,
      tenant: tenant,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          comment: "Test comment",
          end_at: ~T[06:00:00],
          log_category_id: log_category.id,
          start_at: ~T[05:00:00],
          tenant_id: tenant.id,
          user_id: user.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      assert html =~ "Select group and project"
      assert html =~ "05:00"
      assert html =~ "06:00"
    end

    test "unauthorized user cannot see log entries", %{
      conn: conn,
      group: group,
      log_category: log_category,
      project: project,
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
          comment: "Test comment",
          end_at: ~T[06:00:00],
          log_category_id: log_category.id,
          start_at: ~T[05:00:00],
          tenant_id: tenant.id,
          user_id: another_user.id
        })

      assert {:ok, _, html} =
               conn
               |> log_in_user(user)
               |> live(
                 ~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}"
               )

      refute html =~ "05:00"
      refute html =~ "06:00"
    end
  end
end
