defmodule OmedisWeb.OrganisationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Organisation

  describe "/organisations" do
    setup do
      # Create users
      {:ok, user_1} = create_user()
      {:ok, user_2} = create_user()

      # Create organisations
      {:ok, organisation} = create_organisation()

      # Create groups
      {:ok, group_1} = create_group(organisation)
      {:ok, group_2} = create_group(organisation)

      # Associate users with groups
      {:ok, _} =
        create_group_membership(organisation, %{group_id: group_1.id, user_id: user_1.id})

      {:ok, _} =
        create_group_membership(organisation, %{group_id: group_2.id, user_id: user_2.id})

      # Create organisations (15 for user_1, 5 for user_2)
      organisations =
        for i <- 1..20 do
          {:ok, organisation} =
            create_organisation(%{
              name: "Organisation #{String.pad_leading("#{i}", 2, "0")}",
              slug: "organisation-#{i}"
            })

          organisation
        end

      # Set up access rights for user_1 (15 organisations)
      Enum.each(1..15, fn i ->
        {:ok, _} =
          create_access_right(Enum.at(organisations, i - 1), %{
            group_id: group_1.id,
            read: true,
            resource_name: "Organisation"
          })
      end)

      # Set up access rights for user_2 (5 organisations)
      Enum.each(16..20, fn i ->
        {:ok, _} =
          create_access_right(Enum.at(organisations, i - 1), %{
            group_id: group_2.id,
            read: true,
            resource_name: "Organisation"
          })
      end)

      %{user_1: user_1, user_2: user_2, organisations: organisations}
    end

    test "lists all organisations with pagination", %{conn: conn, user_1: user_1} do
      {:ok, index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/organisations")

      assert html =~ "Listing Organisations"
      assert html =~ "Organisation 01"
      assert html =~ "Organisation 10"
      refute html =~ "Organisation 11"

      assert index_live |> element("#organisations") |> render() =~ "Organisation 01"

      # Test pagination
      assert index_live |> element("nav[aria-label=Pagination]") |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      refute html =~ "Organisation 01"
      refute html =~ "Organisation 10"
      assert html =~ "Organisation 11"
      assert html =~ "Organisation 15"
      refute html =~ "Organisation 16"
    end

    test "filters organisations based on user access rights", %{
      conn: conn,
      user_1: user_1,
      user_2: user_2
    } do
      # Test for user_1
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/organisations")

      assert html =~ "Organisation 01"
      assert html =~ "Organisation 10"
      refute html =~ "Organisation 16"

      # Test for user_2
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/organisations")

      refute html =~ "Organisation 01"
      refute html =~ "Organisation 15"
      assert html =~ "Organisation 16"
      assert html =~ "Organisation 20"
    end

    test "shows organisations owned by the user", %{
      conn: conn,
      user_2: user_2,
      organisations: organisations
    } do
      # Assign ownership of an organisation to user_2
      # This organisation is not in user_2's access rights
      owned_organisation = Enum.at(organisations, 0)

      {:ok, _} =
        Organisation.update(owned_organisation, %{owner_id: user_2.id}, authorize?: false)

      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/organisations")

      assert html =~ owned_organisation.name
    end

    test "shows organisations count", %{conn: conn, organisations: organisations, user_1: user_1} do
      owned_organisation = Enum.at(organisations, 15)

      {:ok, _} =
        Organisation.update(owned_organisation, %{owner_id: user_1.id}, authorize?: false)

      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/organisations")

      assert html =~ "Organisations (16)"
    end

    test "shows create button when user does not have an organisation", %{conn: conn} do
      {:ok, user} = create_user()

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations")

      assert html =~ "New Organisation"

      assert index_live |> element("a", "New Organisation") |> render_click() =~
               "New Organisation"

      assert_patch(index_live, ~p"/organisations/new")
    end

    test "does not show create button when user does not have access", %{
      conn: conn,
      user_1: user_1
    } do
      {:ok, _organisation} = create_organisation(%{owner_id: user_1.id})

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user_1)
        |> live(~p"/organisations")

      refute index_live |> element("a", "New Organisation") |> has_element?()
    end
  end

  describe "/organisations/new" do
    setup [:register_and_log_in_user]

    test "redirects when user can't create an organisation", %{conn: conn, user: user} do
      # Create an organisation for the user to make them ineligible for creating another
      {:ok, _organisation} = create_organisation(%{owner_id: user.id})

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/organisations/new")

      assert path == ~p"/organisations"
      assert flash["error"] =~ "You are not authorized to access this page"
    end

    test "creates a new organisation when user has access", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/organisations/new")

      assert index_live
             |> form("#organisation-form", organisation: %{name: "", slug: ""})
             |> render_change() =~ "is required"

      attrs =
        Organisation
        |> attrs_for(nil)
        |> Enum.reject(fn {_k, v} -> is_function(v) end)
        |> Enum.into(%{})
        |> Map.put(:name, "Test Organisation")

      assert {:ok, _index_live, html} =
               index_live
               |> form("#organisation-form", organisation: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/organisations")

      assert html =~ "Organisation saved."
      assert html =~ "Test Organisation"
    end
  end

  describe "/organisations/:slug/edit" do
    setup [:register_and_log_in_user]

    setup %{user: user} do
      {:ok, organisation} =
        create_organisation(%{name: "Test Organisation", slug: "test-organisation"})

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
          update: false,
          write: false
        })

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/organisations/#{organisation}/edit")

      assert path == ~p"/organisations"
      assert flash["error"] == "You are not authorized to access this page"
    end

    test "edits the organisation when user has access", %{conn: conn, user: user} do
      {:ok, organisation} = create_organisation(%{owner_id: user.id}, actor: user)

      {:ok, show_live, _html} = live(conn, ~p"/organisations/#{organisation}/edit")

      assert show_live
             |> form("#organisation-form", organisation: %{street: ""})
             |> render_change() =~ "is required"

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
end
