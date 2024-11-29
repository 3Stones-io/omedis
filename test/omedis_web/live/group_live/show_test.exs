defmodule OmedisWeb.GroupLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, user} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: user.id})

    %{organisation: organisation, user: user}
  end

  describe "/organisations/:slug/groups/:group_slug" do
    test "renders group details if user is the organisation owner", %{
      conn: conn,
      organisation: organisation,
      user: user
    } do
      {:ok, group} = create_group(organisation, %{name: "Test Group"})
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          resource_name: "Group",
          read: true
        })

      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation}/groups/#{group}")

      assert html =~ "Slug"
      assert html =~ "Test Group"
    end

    test "renders group details is a user is authorized", %{
      conn: conn,
      organisation: organisation
    } do
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(organisation, %{name: "Test Group"})

      {:ok, _} =
        create_group_membership(organisation, %{
          group_id: group.id,
          user_id: authorized_user.id
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          resource_name: "Organisation",
          read: true
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          resource_name: "Group",
          read: true
        })

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/groups/#{group}")

      assert html =~ "Test Group"
    end

    test "does not render a group details if user is unauthorized", %{
      conn: conn,
      user: user
    } do
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)
      {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          resource_name: "Group",
          read: false
        })

      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation}/groups/#{group}")
      end
    end
  end
end
