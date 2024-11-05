defmodule OmedisWeb.GroupLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    {:ok, user} = create_user()

    {:ok, organisation} = create_organisation(%{owner_id: user.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})

    create_group_user(%{group_id: group.id, user_id: user.id})

    create_access_right(%{
      group_id: group.id,
      resource_name: "Group",
      organisation_id: organisation.id,
      read: true,
      write: true
    })

    %{
      group: group,
      tenant: organisation,
      user: user
    }
  end

  describe "/organisations/:slug/groups/:group_slug" do
    test "renders group details if user is the organisation owner", %{
      conn: conn,
      group: group,
      tenant: organisation,
      user: user
    } do
      {:ok, _, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}")

      assert html =~ "Slug"
      assert html =~ group.name
    end

    test "renders group details is a user is authorized", %{
      conn: conn,
      tenant: organisation
    } do
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(%{organisation_id: organisation.id})

      create_group_user(%{
        group_id: group.id,
        user_id: authorized_user.id
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "Organisation",
        organisation_id: organisation.id,
        read: true,
        write: true
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "Group",
        organisation_id: organisation.id,
        read: true,
        write: true
      })

      {:ok, _, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}")

      assert html =~ group.name
    end

    test "does not render a group details if user is unauthorized", %{
      conn: conn,
      user: user
    } do
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(%{organisation_id: organisation.id})
      create_group_user(%{group_id: group.id, user_id: user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "Group",
        organisation_id: organisation.id,
        read: false,
        write: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        conn
        |> log_in_user(user)
        |> live(~p"/organisations/#{organisation.slug}/groups/#{group.slug}")
      end
    end
  end
end
