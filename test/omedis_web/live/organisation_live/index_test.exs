defmodule OmedisWeb.OrganisationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  describe "/organisations" do
    setup do
      # Create users
      {:ok, user_1} = create_user()
      organisation = fetch_users_organisation(user_1.id)

      %{
        user_1: user_1,
        organisation: organisation
      }
    end

    test "shows organisation details", %{
      conn: conn,
      user_1: user_1,
      organisation: organisation
    } do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/organisations")

      assert html =~ "Listing Organisations"
      assert html =~ organisation.name
    end
  end

  describe "/organisations/:slug/edit" do
    setup [:register_and_log_in_user]

    setup %{user: user} do
      {:ok, organisation} = create_organisation(%{name: "Test Organisation"})

      {:ok, group} = create_group(organisation)
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

      {:ok, organisation: organisation, group: group}
    end

    test "redirects when user can't edit the organisation", %{
      conn: conn,
      group: group,
      organisation: organisation
    } do
      {:ok, _access_right} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation",
          update: false
        })

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/organisations/#{organisation}/edit")

      assert path == ~p"/organisations"
      assert flash["error"] == "You are not authorized to access this page"
    end

    test "shows form errors", %{conn: conn, user: user} do
      organisation = fetch_users_organisation(user.id)
      {:ok, show_live, _html} = live(conn, ~p"/organisations/#{organisation}/edit")

      html =
        show_live
        |> form("#organisation-form", organisation: %{name: ""})
        |> render_submit()

      assert html =~ "is required"
    end

    test "edits the organisation when user has access", %{conn: conn, user: user} do
      organisation = fetch_users_organisation(user.id)

      {:ok, show_live, _html} = live(conn, ~p"/organisations/#{organisation}/edit")

      attrs = %{name: "Updated Organisation"}

      assert {:ok, _show_live, html} =
               show_live
               |> form("#organisation-form", organisation: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/organisations/#{Slug.slugify(attrs.name)}")

      assert html =~ "Organisation saved"
      assert html =~ "Updated Organisation"
    end
  end
end
