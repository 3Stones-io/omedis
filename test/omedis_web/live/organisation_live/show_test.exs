defmodule OmedisWeb.OrganisationLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  alias Omedis.Accounts.Organisation

  setup [:register_and_log_in_user]

  setup %{user: user} do
    organisation = fetch_users_organisation(user.id)

    {:ok, group} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

    {:ok, organisation: organisation, group: group, user: user}
  end

  describe "/organisations/:slug" do
    test "shows organisation page when user has read access or is owner", %{
      conn: conn,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, _access_right} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation}")

      assert html =~ organisation.name
      assert html =~ user.first_name <> " " <> user.last_name
    end

    test "doesn't show organisation page when user has no read access", %{conn: conn} do
      {:ok, organisation} = create_organisation()

      assert_raise Ash.Error.Query.NotFound, fn ->
        live(conn, ~p"/organisations/#{organisation}")
      end
    end

    test "shows organisation page for owner without access rights", %{
      conn: conn,
      organisation: organisation
    } do
      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation}")

      assert html =~ organisation.name
    end

    test "shows edit button when user has update access", %{
      group: group,
      organisation: organisation
    } do
      {:ok, user} = create_user()
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

      {:ok, access_right} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation",
          update: false
        })

      conn =
        build_conn()
        |> log_in_user(user)

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation}")

      refute html =~ "Edit organisation"

      Ash.update!(access_right, %{update: true})

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation}")
      assert html =~ "Edit organisation"
    end

    test "shows edit button for organisation owner", %{
      conn: conn,
      user: user
    } do
      {:ok, owned_organisation} =
        create_organisation(
          %{
            name: "Owned Organisation",
            slug: "owned-organisation",
            owner_id: user.id
          },
          actor: user
        )

      {:ok, show_live, html} = live(conn, ~p"/organisations/#{owned_organisation}")

      assert html =~ "Edit organisation"

      assert show_live |> element("a", "Edit organisation") |> render_click() =~
               "Edit Organisation"

      assert_patch(show_live, ~p"/organisations/#{owned_organisation}/show/edit")

      html =
        show_live
        |> form("#organisation-form", organisation: %{name: "", slug: ""})
        |> render_change()

      assert html =~ "is required"

      attrs =
        Organisation
        |> attrs_for(nil)
        |> Enum.reject(fn {_k, v} -> is_function(v) end)
        |> Enum.into(%{})
        |> Map.put(:name, "Updated Organisation")

      assert {:ok, _show_live, html} =
               show_live
               |> form("#organisation-form", organisation: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/organisations/#{attrs.slug}")

      assert html =~ "Organisation saved"
      assert html =~ "Updated Organisation"
    end
  end

  describe "/organisations/:slug (Time Tracker)" do
    alias Omedis.Accounts.Event
    alias OmedisWeb.Endpoint

    setup %{group: group, organisation: organisation, user: user} do
      {:ok, project} = create_project(organisation)

      {:ok, activity_1} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 1",
          color_code: "#FF0000"
        })

      {:ok, activity_2} =
        create_activity(organisation, %{
          group_id: group.id,
          project_id: project.id,
          name: "Activity 2",
          color_code: "#00FF00"
        })

      %{
        activity_1: activity_1,
        activity_2: activity_2,
        group: group,
        organisation: organisation,
        project: project,
        user: user
      }
    end

    test "shows time tracker with the Start Timer button when there is no active activity", %{
      conn: conn,
      organisation: organisation
    } do
      {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation}")

      wait_until(fn ->
        html = render(view)
        assert html =~ "Start Timer"
        assert html =~ "hero-play-circle-solid"
      end)
    end

    test "starts timer when activity is selected", %{
      activity_1: activity_1,
      conn: conn,
      organisation: organisation,
      user: user
    } do
      pubsub_topics_unique_id = Ash.UUID.generate()

      :ok = Endpoint.subscribe("current_activity_#{pubsub_topics_unique_id}")
      :ok = Endpoint.subscribe("current_organisation_#{pubsub_topics_unique_id}")

      {:ok, organisation_live_view, _html} =
        conn
        |> put_session("pubsub_topics_unique_id", pubsub_topics_unique_id)
        |> live(~p"/organisations/#{organisation}")

      # Wait for TimeTrackerLiveView to receive organisation assigns
      wait_until(fn ->
        html = render(organisation_live_view)
        assert html =~ "Start Timer"
      end)

      assert time_tracker_live_view =
               find_live_child(organisation_live_view, "time-tracker-liveview")

      # Select an activity
      time_tracker_live_view
      |> element("button[phx-click='select_activity'][phx-value-activity_id='#{activity_1.id}']")
      |> render_click()

      assert_broadcast "event_started", %Omedis.Accounts.Activity{id: broadcast_activity_id}, 1000
      assert broadcast_activity_id == activity_1.id

      html = render(time_tracker_live_view)

      refute html =~ "Start Timer"
      assert html =~ "animate-pulse"

      assert {:ok, [event]} =
               Event.by_activity_today(
                 %{activity_id: activity_1.id},
                 actor: user,
                 tenant: organisation
               )

      assert event.activity_id == activity_1.id
      assert is_nil(event.dtend)
    end

    test "infinite scroll works in both directions", %{
      conn: conn,
      group: group,
      organisation: organisation,
      project: project
    } do
      for i <- 1..15 do
        {:ok, _activity} =
          create_activity(organisation, %{
            group_id: group.id,
            project_id: project.id,
            name: "Activity #{i}"
          })
      end

      pubsub_topics_unique_id = Ash.UUID.generate()

      :ok = Endpoint.subscribe("current_activity_#{pubsub_topics_unique_id}")
      :ok = Endpoint.subscribe("current_organisation_#{pubsub_topics_unique_id}")

      {:ok, organisation_live_view, _html} =
        conn
        |> put_session("pubsub_topics_unique_id", pubsub_topics_unique_id)
        |> live(~p"/organisations/#{organisation}")

      # Wait for TimeTrackerLiveView to receive organisation assigns
      wait_until(fn ->
        html = render(organisation_live_view)
        assert html =~ "Start Timer"
      end)

      assert time_tracker_live_view =
               find_live_child(organisation_live_view, "time-tracker-liveview")

      html = render(time_tracker_live_view)

      refute html =~ "Activity 15"
      refute html =~ "Activity 13"

      html_2 = render_hook(time_tracker_live_view, "next-page")

      assert html_2 =~ "Activity 15"
      assert html_2 =~ "Activity 13"

      html_3 = render_hook(time_tracker_live_view, "previous-page")

      assert html_3 =~ "Activity 15"
      assert html_3 =~ "Activity 4"
      assert html_3 =~ "Activity 2"
    end

    test "stops timer when clicking active activity", %{
      conn: conn,
      organisation: organisation,
      activity_1: activity_1,
      user: user
    } do
      pubsub_topics_unique_id = Ash.UUID.generate()

      :ok = Endpoint.subscribe("current_activity_#{pubsub_topics_unique_id}")
      :ok = Endpoint.subscribe("current_organisation_#{pubsub_topics_unique_id}")

      {:ok, organisation_live_view, _html} =
        conn
        |> put_session("pubsub_topics_unique_id", pubsub_topics_unique_id)
        |> live(~p"/organisations/#{organisation}")

      # Wait for TimeTrackerLiveView to receive organisation assigns
      wait_until(fn ->
        html = render(organisation_live_view)
        assert html =~ "Start Timer"
      end)

      assert time_tracker_live_view =
               find_live_child(organisation_live_view, "time-tracker-liveview")

      # Select an activity
      html =
        time_tracker_live_view
        |> element(
          "button[phx-click='select_activity'][phx-value-activity_id='#{activity_1.id}']"
        )
        |> render_click()

      assert_broadcast "event_started", %Omedis.Accounts.Activity{id: broadcast_activity_id}, 1000
      assert broadcast_activity_id == activity_1.id

      refute html =~ "Start Timer"
      assert html =~ "animate-pulse"

      # Verify event was started
      assert {:ok, [event]} =
               Event.by_activity_today(
                 %{activity_id: activity_1.id},
                 actor: user,
                 tenant: organisation
               )

      assert event.activity_id == activity_1.id
      assert is_nil(event.dtend)

      assert time_tracker_live_view
             |> element("#time-tracker-stop-event")
             |> has_element?()

      # Stop activity
      assert time_tracker_live_view
             |> element("#time-tracker-stop-event")
             |> render_click() =~ "Start Timer"

      assert_broadcast "event_stopped", %{}, 1000
      assert broadcast_activity_id == activity_1.id

      # Verify event was stopped
      assert {:ok, [event]} =
               Event.by_activity_today(
                 %{activity_id: activity_1.id},
                 actor: user,
                 tenant: organisation
               )

      assert event.activity_id == activity_1.id
      refute is_nil(event.dtend)
    end

    test "maintains timer state on page reload", %{
      conn: conn,
      organisation: organisation,
      activity_1: activity_1,
      user: user
    } do
      pubsub_topics_unique_id = Ash.UUID.generate()

      :ok = Endpoint.subscribe("current_activity_#{pubsub_topics_unique_id}")
      :ok = Endpoint.subscribe("current_organisation_#{pubsub_topics_unique_id}")

      {:ok, organisation_live_view, _html} =
        conn
        |> put_session("pubsub_topics_unique_id", pubsub_topics_unique_id)
        |> live(~p"/organisations/#{organisation}")

      # Wait for TimeTrackerLiveView to receive organisation assigns
      wait_until(fn ->
        html = render(organisation_live_view)
        assert html =~ "Start Timer"
      end)

      assert time_tracker_live_view =
               find_live_child(organisation_live_view, "time-tracker-liveview")

      # Select an activity
      html =
        time_tracker_live_view
        |> element(
          "button[phx-click='select_activity'][phx-value-activity_id='#{activity_1.id}']"
        )
        |> render_click()

      assert_broadcast "event_started", %Omedis.Accounts.Activity{id: broadcast_activity_id}, 1000
      assert broadcast_activity_id == activity_1.id

      # Verify timer is running
      refute html =~ "Start Timer"
      assert html =~ "animate-pulse"

      # Verify event was started
      assert {:ok, [event]} =
               Event.by_activity_today(
                 %{activity_id: activity_1.id},
                 actor: user,
                 tenant: organisation
               )

      assert event.activity_id == activity_1.id
      assert is_nil(event.dtend)

      # Simulate page reload
      {:ok, new_view, _html} = live(conn, ~p"/organisations/#{organisation}")

      # Wait for TimeTrackerLiveView to receive organisation assigns
      wait_until(fn ->
        html = render(new_view)

        # Verify timer is still running
        refute html =~ "Start Timer"
        assert html =~ "animate-pulse"
      end)
    end

    test "unauthorized user cannot see time tracker", %{
      conn: conn,
      group: group,
      organisation: organisation
    } do
      {:ok, unauthorized_user} = create_user()

      {:ok, _} =
        create_group_membership(organisation, %{group_id: group.id, user_id: unauthorized_user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, view, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/organisations/#{organisation}")

      refute html =~ "Start Timer"

      refute view
             |> element("button", "Start Timer")
             |> has_element?()
    end
  end

  defp wait_until(fun), do: wait_until(1_000, fun)
  defp wait_until(0, fun), do: fun.()

  defp wait_until(timeout, fun) do
    fun.()
  rescue
    ExUnit.AssertionError ->
      :timer.sleep(10)
      wait_until(max(0, timeout - 10), fun)
  end
end
