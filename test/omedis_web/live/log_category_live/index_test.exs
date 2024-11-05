defmodule OmedisWeb.LogCategoryLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.LogCategory

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, project} = create_project(%{organisation_id: organisation.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        organisation_id: organisation.id,
        write: true
      })

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
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    {:ok, user} = create_user()
    {:ok, group2} = create_group(%{organisation_id: organisation.id})
    {:ok, _} = create_group_user(%{group_id: group2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Group",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Project",
        organisation_id: organisation.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group2.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id
      })

    %{
      authorized_user: authorized_user,
      group: group,
      group2: group2,
      owner: owner,
      project: project,
      tenant: organisation,
      user: user
    }
  end

  describe "/organisations/:slug/groups/:group_slug/log_categories" do
    test "lists all log categories if user is organisation owner", %{
      conn: conn,
      group: group,
      project: project,
      tenant: organisation,
      owner: owner
    } do
      {:ok, _log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Category"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "Test Category"
    end

    test "lists all log categories if user is authorized", %{
      conn: conn,
      group: group,
      project: project,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, _log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Category"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      assert html =~ "Test Category"
    end

    test "unauthorized user cannot see log categories", %{
      conn: conn,
      group: group,
      project: project,
      tenant: organisation,
      user: user
    } do
      {:ok, _log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Category"
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      refute html =~ "Test Category"
      refute html =~ "New Log Category"
    end
  end

  describe "/organisations/:slug/groups/:group_slug/log_categories/new" do
    test "organisation owner can create new log category", %{
      conn: conn,
      group: group,
      project: project,
      tenant: organisation,
      owner: owner
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/new")

      assert html =~ "New Log Category"

      assert html =
               view
               |> form("#log_category-form",
                 log_category: %{
                   name: "New Category",
                   project_id: project.id,
                   slug: "new-category"
                 }
               )
               |> render_submit()

      assert_patch(
        view,
        ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories"
      )

      assert html =~ "Log category saved successfully"
      assert html =~ "New Category"
    end

    test "authorized user can create new log category", %{
      conn: conn,
      group: group,
      project: project,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/new")

      assert html =~ "New Log Category"

      assert html =
               view
               |> form("#log_category-form",
                 log_category: %{
                   name: "New Category",
                   project_id: project.id,
                   slug: "new-category"
                 }
               )
               |> render_submit()

      assert_patch(
        view,
        ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories"
      )

      assert html =~ "Log category saved successfully"
      assert html =~ "New Category"
    end

    test "unauthorized user cannot create new log category", %{
      conn: conn,
      group: group,
      tenant: organisation,
      user: user
    } do
      {:error, {:live_redirect, %{flash: flash, to: to}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/new")

      assert to == ~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories"
      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows validation errors", %{
      conn: conn,
      group: group,
      tenant: organisation,
      authorized_user: authorized_user
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories/new")

      html =
        view
        |> form("#log_category-form", log_category: %{name: "", slug: ""})
        |> render_change()

      assert html =~ "must be present"
    end
  end

  describe "position updates" do
    test "authorized user can move log categories up and down", %{
      conn: conn,
      group: group,
      tenant: organisation,
      project: project,
      authorized_user: authorized_user
    } do
      # Create categories with sequential positions
      categories =
        Enum.map(1..3, fn i ->
          {:ok, log_category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id,
              name: "Log Category #{i}"
            })

          log_category
        end)

      [first, second, third] = categories

      {:ok, view, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      # Verify position controls are rendered
      assert html =~ "move-up-#{second.id}"
      assert html =~ "move-down-#{second.id}"

      # Test moving up
      assert view
             |> element("#move-up-#{second.id}")
             |> render_click()

      :timer.sleep(1000)

      # Verify positions after moving up
      assert Ash.get!(LogCategory, second.id, authorize?: false).position == 1
      assert Ash.get!(LogCategory, first.id, authorize?: false).position == 2
      assert Ash.get!(LogCategory, third.id, authorize?: false).position == 3
    end

    test "unauthorized user cannot see position controls", %{
      conn: conn,
      group: group,
      tenant: organisation,
      project: project,
      user: unauthorized_user
    } do
      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id,
          name: "Test Category"
        })

      {:ok, view, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      refute html =~ "move-up-#{log_category.id}"
      refute html =~ "move-down-#{log_category.id}"
      refute view |> element(".position-up") |> has_element?()
      refute view |> element(".position-down") |> has_element?()
    end

    test "organisation owner can move log categories up and down", %{
      conn: conn,
      group: group,
      tenant: organisation,
      project: project,
      owner: owner
    } do
      categories =
        Enum.map(1..3, fn i ->
          {:ok, log_category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id,
              name: "Log Category #{i}"
            })

          log_category
        end)

      [first, second, third] = categories

      {:ok, view, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}/log_categories")

      # Test moving up
      view
      |> element("#move-up-#{second.id}")
      |> render_click()

      :timer.sleep(1000)

      # Verify positions after moving up
      assert Ash.get!(LogCategory, second.id, authorize?: false).position == 1
      assert Ash.get!(LogCategory, first.id, authorize?: false).position == 2
      assert Ash.get!(LogCategory, third.id, authorize?: false).position == 3

      # Test moving down
      view
      |> element("#move-down-#{first.id}")
      |> render_click()

      # Verify positions after moving down
      assert Ash.get!(LogCategory, second.id, authorize?: false).position == 1
      assert Ash.get!(LogCategory, third.id, authorize?: false).position == 2
      assert Ash.get!(LogCategory, first.id, authorize?: false).position == 3
    end
  end
end
