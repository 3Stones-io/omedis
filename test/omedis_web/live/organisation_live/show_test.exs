defmodule OmedisWeb.OrganisationLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Organisation

  setup [:register_and_log_in_user]

  setup %{user: user} do
    {:ok, organisation} =
      create_organisation(%{name: "Test Organisation", slug: "test-organisation"})

    {:ok, group} = create_group()
    {:ok, _} = create_group_user(%{group_id: group.id, user_id: user.id})

    {:ok, organisation: organisation, group: group}
  end

  describe "/organisations/:slug" do
    test "shows organisation page when user has read access or is owner", %{
      conn: conn,
      group: group,
      organisation: organisation
    } do
      {:ok, _access_right} =
        create_access_right(%{
          group_id: group.id,
          organisation_id: organisation.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation.slug}")

      assert html =~ organisation.name
    end

    test "doesn't show organisation page when user has no read access", %{conn: conn} do
      {:ok, organisation} = create_organisation()

      assert_raise Ash.Error.Query.NotFound, fn ->
        live(conn, ~p"/organisations/#{organisation.slug}")
      end
    end

    test "shows organisation page for owner without access rights", %{conn: conn, user: user} do
      {:ok, owned_organisation} =
        create_organisation(%{
          name: "Owned Organisation",
          slug: "owned-organisation",
          owner_id: user.id
        })

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{owned_organisation.slug}")

      assert html =~ owned_organisation.name
    end

    test "shows edit button when user has write or update access", %{
      conn: conn,
      group: group,
      organisation: organisation
    } do
      {:ok, access_right} =
        create_access_right(%{
          group_id: group.id,
          organisation_id: organisation.id,
          read: true,
          resource_name: "Organisation",
          update: false,
          write: false
        })

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation.slug}")
      refute html =~ "Edit organisation"

      Ash.update!(access_right, %{write: true, update: false})

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation.slug}")
      assert html =~ "Edit organisation"

      Ash.update!(access_right, %{write: false, update: true})

      {:ok, _show_live, html} = live(conn, ~p"/organisations/#{organisation.slug}")
      assert html =~ "Edit organisation"
    end

    test "shows edit button for organisation owner without access rights", %{
      conn: conn,
      user: user
    } do
      {:ok, owned_organisation} =
        create_organisation(%{
          name: "Owned Organisation",
          slug: "owned-organisation",
          owner_id: user.id
        })

      {:ok, show_live, html} = live(conn, ~p"/organisations/#{owned_organisation.slug}")

      assert html =~ "Edit organisation"

      assert show_live |> element("a", "Edit organisation") |> render_click() =~
               "Edit Organisation"

      assert_patch(show_live, ~p"/organisations/#{owned_organisation.slug}/show/edit")

      assert show_live
             |> form("#organisation-form", organisation: %{street: ""})
             |> render_change() =~ "is required"

      attrs =
        Organisation
        |> attrs_for()
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
