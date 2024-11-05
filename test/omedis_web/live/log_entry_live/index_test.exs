defmodule OmedisWeb.LogEntryLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, project} = create_project(%{organisation_id: organisation.id})
    {:ok, log_category} = create_log_category(%{group_id: group.id, project_id: project.id})
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()
    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogEntry",
        organisation_id: organisation.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    %{
      authorized_user: authorized_user,
      group: group,
      log_category: log_category,
      owner: owner,
      project: project,
      tenant: organisation,
      user: user
    }
  end

  describe "/organisations/:slug/log_categories/:id/log_entries" do
    test "organisation owner can see all log entries", %{
      conn: conn,
      tenant: organisation,
      log_category: log_category,
      owner: owner,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: organisation.id,
          user_id: user.id,
          comment: "User's log entry"
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: organisation.id,
          user_id: owner.id,
          comment: "Owner's log entry"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(owner)
        |> live(
          ~p"/organisations/#{organisation.slug}/log_categories/#{log_category.id}/log_entries"
        )

      assert html =~ "User&#39;s log entry"
      assert html =~ "Owner&#39;s log entry"
    end

    test "authorized user can see all log entries", %{
      authorized_user: authorized_user,
      conn: conn,
      log_category: log_category,
      tenant: organisation,
      user: user
    } do
      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: organisation.id,
          user_id: authorized_user.id,
          comment: "Test comment 1"
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: organisation.id,
          user_id: user.id,
          comment: "Test comment 2"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(
          ~p"/organisations/#{organisation.slug}/log_categories/#{log_category.id}/log_entries"
        )

      assert html =~ "Test comment 1"
      assert html =~ "Test comment 2"
    end

    test "unauthorized user cannot see log entries", %{conn: conn, user: user} do
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(%{organisation_id: organisation.id})
      {:ok, _} = create_group_user(%{group_id: group.id, user_id: user.id})
      {:ok, project} = create_project(%{organisation_id: organisation.id})

      {:ok, log_category} = create_log_category(%{group_id: group.id, project_id: project.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          read: true,
          resource_name: "Organisation",
          organisation_id: organisation.id
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          read: true,
          resource_name: "LogCategory",
          organisation_id: organisation.id
        })

      {:ok, _} =
        create_log_entry(%{
          log_category_id: log_category.id,
          organisation_id: organisation.id,
          user_id: user.id,
          comment: "Test comment"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(
          ~p"/organisations/#{organisation.slug}/log_categories/#{log_category.id}/log_entries"
        )

      refute html =~ "Test comment"
    end
  end
end
