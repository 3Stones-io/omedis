defmodule OmedisWeb.GroupLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.Fixtures
  import Omedis.TestUtils

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test@user.com", groups: [group.id]})

    {:ok, authorized_user} =
      create_user(%{email: "test@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        create: true,
        destroy: true,
        update: true,
        resource_name: "Group"
      })

    {:ok, group2} = create_group(organisation)

    {:ok, _invitation} =
      create_invitation(organisation, %{email: "test2@user.com", groups: [group2.id]})

    {:ok, user} =
      create_user(%{email: "test2@user.com", current_organisation_id: organisation.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group2.id,
        read: true,
        resource_name: "Organisation"
      })

    %{
      authorized_user: authorized_user,
      group: group,
      group2: group2,
      owner: owner,
      organisation: organisation,
      user: user
    }
  end

  describe "/groups" do
    test "list groups with pagination", %{
      authorized_user: authorized_user,
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      Enum.each(3..15, fn i ->
        {:ok, group} =
          create_group(organisation, %{
            user_id: owner.id,
            name: "Group #{i}"
          })

        create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

        create_access_right(organisation, %{
          resource_name: "Group",
          group_id: group.id,
          read: true
        })
      end)

      Enum.each(16..30, fn i ->
        {:ok, group} =
          create_group(organisation, %{
            user_id: owner.id,
            name: "Group #{i}"
          })

        create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

        create_access_right(organisation, %{
          resource_name: "Group",
          group_id: group.id,
          read: false
        })
      end)

      Enum.each(31..40, fn i ->
        {:ok, group} =
          create_group(organisation, %{
            user_id: authorized_user.id,
            name: "Group #{i}"
          })

        create_group_membership(organisation, %{user_id: authorized_user.id, group_id: group.id})

        create_access_right(organisation, %{
          resource_name: "Group",
          group_id: group.id,
          read: false
        })
      end)

      {:ok, view, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups")

      assert html =~ "Listing Groups"
      assert html =~ "New Group"
      assert html =~ "Group 3"
      assert html =~ "Group 8"
      refute html =~ "Group 11"

      assert view |> element("nav[aria-label=Pagination]") |> has_element?()

      view
      |> element("nav[aria-label=Pagination] a", "3")
      |> render_click()

      html = render(view)
      assert html =~ "Group 21"
      refute html =~ "Group 16"
      refute html =~ "Group 37"

      assert view |> element("nav[aria-label=Pagination] a", "4") |> has_element?()

      view
      |> element("nav[aria-label=Pagination] a", "4")
      |> render_click()

      html = render(view)
      refute html =~ "Group 21"
      assert html =~ "Group 37"

      assert view |> element("nav[aria-label=Pagination] a", "5") |> has_element?()

      view
      |> element("nav[aria-label=Pagination] a", "5")
      |> render_click()

      html = render(view)
      refute html =~ "Group 37"
      assert html =~ "Group 40"

      refute view |> element("nav[aria-label=Pagination] a", "6") |> has_element?()
    end

    test "edit and delete actions are hidden is user has no rights to destroy or update a group",
         %{
           conn: conn,
           group: group,
           group2: group2,
           organisation: organisation,
           user: user
         } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          destroy: false,
          update: false,
          resource_name: "Group"
        })

      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/groups")

      refute view |> element("#edit-group-#{group.id}") |> has_element?()
      refute view |> element("#delete-group-#{group.id}") |> has_element?()

      assert html =~ group.name
    end

    test "authorized user can delete a group", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{
          user_id: owner.id,
          name: "Group 1"
        })

      create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: true,
        destroy: true
      })

      {:ok, view, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups")

      assert view
             |> element("#delete-group-#{group.id}")
             |> has_element?()

      assert {:ok, conn} =
               view
               |> element("#delete-group-#{group.id}")
               |> render_click()
               |> follow_redirect(conn)

      html = html_response(conn, 200)

      refute html =~ group.name
    end

    test "authorized user can edit a group", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{
          user_id: owner.id,
          name: "Group 1"
        })

      create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: true,
        update: true
      })

      {:ok, view, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/groups")

      assert view
             |> element("#edit-group-#{group.id}")
             |> has_element?()

      assert view
             |> element("#edit-group-#{group.id}")
             |> render_click() =~ "Edit Group"

      assert view
             |> form("#group-form", group: %{name: "New Group Name"})
             |> render_submit()

      assert_patch(view, ~p"/groups")

      html = render(view)
      assert html =~ "Group updated successfully"
      assert html =~ "New Group Name"
    end
  end

  describe "/groups/:slug/edit" do
    test "can't edit a group if not authorized", %{
      conn: conn,
      group: group,
      group2: group2,
      organisation: organisation,
      user: user
    } do
      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group2.id,
          read: true,
          destroy: false,
          update: false,
          resource_name: "Group"
        })

      {:error, {:redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(user)
        |> live(~p"/groups/#{group}/edit")

      assert path == ~p"/groups"
      assert flash["error"] == "You are not authorized to access this page"
    end
  end
end
