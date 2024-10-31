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

  describe "/tenants/:slug/today" do
    alias Omedis.Accounts.LogEntry

    # test "tenant owner can see log entries", %{
    #   conn: conn,
    #   group: group,
    #   log_category: log_category,
    #   owner: owner,
    #   project: project,
    #   tenant: tenant
    # } do
    #   attrs =
    #     LogEntry
    #     |> attrs_for()
    #     |> Map.put(:log_category_id, log_category.id)
    #     |> Map.put(:tenant_id, tenant.id)
    #     |> Map.put(:user_id, owner.id)

    #   {:ok, _} =
    #     create_log_entry(attrs)

    #   {:ok, _, html} =
    #     conn
    #     |> log_in_user(owner)
    #     |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

    #   File.write!("test.html", html)

    #   assert html =~ "Select group and project"
    #   assert html =~ "05:00"
    #   assert html =~ "06:00"
    # end

    # test "authorized user can see log entries", %{
    #   authorized_user: authorized_user,
    #   conn: conn,
    #   group: group,
    #   log_category: log_category,
    #   project: project,
    #   tenant: tenant,
    #   user: user
    # } do
    #   attrs =
    #     LogEntry
    #     |> attrs_for()
    #     |> Map.put(:log_category_id, log_category.id)
    #     |> Map.put(:tenant_id, tenant.id)
    #     |> Map.put(:user_id, authorized_user.id)

    #   {:ok, _} =
    #     create_log_entry(attrs)

    #   {:ok, _lv, html} =
    #     conn
    #     |> log_in_user(authorized_user)
    #     |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

    #   assert html =~ "Select group and project"
    #   assert html =~ "(00:00)"
    # end

    # test "unauthorized user cannot see log entries", %{
    #   conn: conn,
    #   group: group,
    #   log_category: log_category,
    #   project: project,
    #   user: user
    # } do
    #   {:ok, another_user} = create_user()
    #   {:ok, tenant} = create_tenant(%{owner_id: another_user.id})
    #   {:ok, _} = create_group_user(%{group_id: group.id, user_id: user.id})

    #   {:ok, _} =
    #     create_access_right(%{
    #       group_id: group.id,
    #       read: true,
    #       resource_name: "Tenant",
    #       tenant_id: tenant.id
    #     })

    #   attrs =
    #     LogEntry
    #     |> attrs_for()
    #     |> Map.put(:log_category_id, log_category.id)
    #     |> Map.put(:tenant_id, tenant.id)
    #     |> Map.put(:user_id, user.id)

    #   {:ok, _} =
    #     create_log_entry(attrs)

    #   assert {:ok, _, html} =
    #            conn
    #            |> log_in_user(user)
    #            |> live(
    #              ~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}"
    #            )

    #   refute html =~ "(00:00)"
    # end

    test "tenant owner can create a new log entry when selecting a log category", %{
      conn: conn,
      group: group,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: tenant
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Verify a new log entry was created
      {:ok, log_entries} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: owner,
          tenant: tenant
        )

      assert length(log_entries) == 1
      log_entry = hd(log_entries)
      assert log_entry.log_category_id == log_category.id
      assert log_entry.user_id == owner.id
      assert log_entry.tenant_id == tenant.id
    end

    test "tenant owner can stop active log entry when selecting same category again", %{
      conn: conn,
      group: group,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: tenant
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      # Create initial log entry
      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Click same category again to stop it
      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Verify log entry was stopped (end_at was set)
      {:ok, log_entries} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: owner,
          tenant: tenant
        )

      log_entry = hd(log_entries)
      assert log_entry.log_category_id == log_category.id
      # TODO: This should pass as-is, but it's failing.
      assert not is_nil(log_entry.end_at)
    end

    test "tenant owner can switch active log entry when selecting different category", %{
      conn: conn,
      group: group,
      owner: owner,
      project: project,
      tenant: tenant
    } do
      {:ok, log_category_1} =
        create_log_category(%{group_id: group.id, project_id: project.id, name: "Category 1"})

      {:ok, log_category_2} =
        create_log_category(%{group_id: group.id, project_id: project.id, name: "Category 2"})

      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      # Start log entry for first category
      lv
      |> element("#log-category-#{log_category_1.id}")
      |> render_click()

      # Switch to second category
      lv
      |> element("#log-category-#{log_category_2.id}")
      |> render_click()

      # Verify first log entry was stopped
      # TODO: Fix this test
      {:ok, [entry_1]} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category_1.id},
          actor: owner,
          tenant: tenant
        )

      assert not is_nil(entry_1.end_at)

      # Verify second log entry is active
      {:ok, entries_2} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category_2.id},
          actor: owner,
          tenant: tenant
        )

      entry_2 = List.last(entries_2)
      assert is_nil(entry_2.end_at)
    end

    test "authorized user can create a new log entry when selecting a log category", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      log_category: log_category,
      project: project,
      tenant: tenant
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Verify a new log entry was created
      {:ok, log_entries} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: authorized_user,
          tenant: tenant
        )

      assert length(log_entries) == 1
      log_entry = hd(log_entries)
      assert log_entry.log_category_id == log_category.id
      assert log_entry.user_id == authorized_user.id
      assert log_entry.tenant_id == tenant.id
    end

    test "authorized user can stop active log entry when selecting same category again", %{
      conn: conn,
      group: group,
      log_category: log_category,
      authorized_user: authorized_user,
      project: project,
      tenant: tenant
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      # Create initial log entry
      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Click same category again to stop it
      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Verify log entry was stopped (end_at was set)
      {:ok, log_entries} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: authorized_user,
          tenant: tenant
        )

      log_entry = hd(log_entries)
      assert log_entry.log_category_id == log_category.id
      # TODO: Fix this test
      assert not is_nil(log_entry.end_at)
    end

    test "authorized user can switch active log entry when selecting different category", %{
      conn: conn,
      group: group,
      authorized_user: authorized_user,
      project: project,
      tenant: tenant
    } do
      # Create second log category
      {:ok, log_category_1} =
        create_log_category(%{group_id: group.id, project_id: project.id, name: "Category 1"})

      {:ok, log_category_2} =
        create_log_category(%{group_id: group.id, project_id: project.id, name: "Category 2"})

      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      # Start log entry for first category
      lv
      |> element("#log-category-#{log_category_1.id}")
      |> render_click()

      # Switch to second category
      lv
      |> element("#log-category-#{log_category_2.id}")
      |> render_click()

      # Verify first log entry was stopped
      # TODO: Fix this test
      {:ok, [entry_1]} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category_1.id},
          actor: authorized_user,
          tenant: tenant
        )

      assert not is_nil(entry_1.end_at)

      # Verify second log entry is active
      {:ok, entries_2} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category_2.id},
          actor: authorized_user,
          tenant: tenant
        )

      entry_2 = List.last(entries_2)
      assert is_nil(entry_2.end_at)
    end

    test "unauthorized user cannot create log entries", %{
      conn: conn,
      group: group,
      log_category: log_category,
      project: project,
      tenant: tenant,
      user: user
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      {:ok, log_entries} =
        LogEntry.by_log_category_today(
          %{log_category_id: log_category.id},
          actor: user,
          tenant: tenant
        )

      assert length(log_entries) == 0
    end

    test "unauthorized user cannot stop log entries", %{
      authorized_user: authorized_user,
      conn: conn,
      group: group,
      log_category: log_category,
      project: project,
      tenant: tenant,
      user: unauthorized_user
    } do
      attrs =
        LogEntry
        |> attrs_for()
        |> Map.put(:log_category_id, log_category.id)
        |> Map.put(:tenant_id, tenant.id)
        |> Map.put(:user_id, authorized_user.id)

      {:ok, _} =
        create_log_entry(attrs)

      {:ok, _} = create_group_user(%{group_id: group.id, user_id: unauthorized_user.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          read: true,
          resource_name: "Tenant",
          tenant_id: tenant.id
        })

      # Start log entry as authorized user
      {:ok, lv, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # Log out authorized user and log in unauthorized user
      updated_conn =
        conn
        |> Plug.Conn.fetch_session()
        |> Plug.Conn.clear_session()

      {:ok, lv, _html} =
        updated_conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant.slug}/today?group_id=#{group.id}&project_id=#{project.id}")

      lv
      |> element("#log-category-#{log_category.id}")
      |> render_click()

      # {:ok, log_entries} =
      #   LogEntry.by_log_category_today(
      #     %{log_category_id: log_category.id},
      #     actor: user,
      #     tenant: tenant
      #   )

      # assert length(log_entries) == 0
    end
  end
end
