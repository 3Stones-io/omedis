defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Omedis.Fixtures

  alias Omedis.Accounts.Invitation

  require Ash.Query

  setup do
    {:ok, owner} = create_user()

    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})

    {:ok, authorized_user} = create_user()
    create_group_membership(%{user_id: authorized_user.id, group_id: group.id})

    create_access_right(%{
      resource_name: "Invitation",
      create: true,
      organisation_id: organisation.id,
      group_id: group.id,
      write: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Organisation",
      organisation_id: organisation.id,
      write: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      organisation_id: organisation.id,
      write: true
    })

    {:ok, unauthorized_user} = create_user()
    {:ok, group_2} = create_group()
    {:ok, _} = create_group_membership(%{user_id: unauthorized_user.id, group_id: group_2.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      organisation: organisation,
      unauthorized_user: unauthorized_user
    }
  end

  describe "/organisations/:slug/invitations/new" do
    test "organisation owner can create an invitation", %{
      conn: conn,
      group: group,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, view, _html} =
               conn
               |> log_in_user(owner)
               |> live(~p"/organisations/#{organisation}/invitations/new")

      view
      |> form("#invitation-form",
        invitation: %{
          email: "test@example.com",
          language: "en",
          groups: %{group.id => true}
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/organisations/#{organisation}")

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups])

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.organisation_id == organisation.id
      assert Enum.map(invitation.groups, & &1.id) == [group.id]
    end

    test "authorized user can create an invitation", %{
      conn: conn,
      group: group,
      authorized_user: authorized_user,
      organisation: organisation
    } do
      assert {:ok, view, _html} =
               conn
               |> log_in_user(authorized_user)
               |> live(~p"/organisations/#{organisation}/invitations/new")

      view
      |> form("#invitation-form",
        invitation: %{
          email: "test@example.com",
          language: "en",
          groups: %{group.id => true}
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/organisations/#{organisation}")

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups])

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == authorized_user.id
      assert invitation.organisation_id == organisation.id
      assert Enum.map(invitation.groups, & &1.id) == [group.id]
    end

    test "unauthorized user cannot access new invitation page", %{
      conn: conn,
      unauthorized_user: user
    } do
      {:ok, organisation} = create_organisation()

      {:ok, group} =
        create_group(%{organisation_id: organisation.id, user_id: user.id})

      create_group_membership(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Organisation",
        organisation_id: organisation.id,
        group_id: group.id,
        read: true
      })

      assert {:error, {:live_redirect, %{to: path}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/organisations/#{organisation}/invitations/new")

      assert path == ~p"/organisations/#{organisation}"
    end
  end
end
