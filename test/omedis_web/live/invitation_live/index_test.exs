defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  require Ash.Query

  alias Omedis.Invitations.Invitation

  setup do
    {:ok, owner} = create_user()

    organisation = fetch_users_organisation(owner.id)

    {:ok, group} = create_group(organisation)
    {:ok, authorized_user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "Invitation",
        create: true,
        destroy: true,
        group_id: group.id,
        read: true
      })

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
        resource_name: "Group",
        create: true
      })

    {:ok, unauthorized_user} = create_user()
    {:ok, group_2} = create_group(organisation)

    {:ok, _} =
      create_group_membership(organisation, %{user_id: unauthorized_user.id, group_id: group_2.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      organisation: organisation,
      unauthorized_user: unauthorized_user
    }
  end

  describe "/organisations/:slug/invitations" do
    setup %{owner: owner, authorized_user: authorized_user, organisation: organisation} do
      # Create invitations (15 for owner, 5 for user_2)
      invitations =
        for i <- 1..20 do
          {:ok, invitation} =
            create_invitation(organisation, %{
              email: "test#{i}@example.com",
              creator_id: if(Enum.random([true, false]), do: owner.id, else: authorized_user.id),
              language: "en"
            })

          invitation
          |> Ash.Changeset.for_update(
            :update,
            %{inserted_at: Omedis.TestUtils.time_after(-i * 12_000)},
            authorize?: false
          )
          |> Ash.update!()
        end

      %{invitations: invitations}
    end

    test "organisation owner can see all invitations with pagination", %{
      conn: conn,
      owner: owner,
      organisation: organisation
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert html =~ "Listing Invitations"
      refute html =~ "test1@example.com"
      refute html =~ "test2@example.com"
      refute html =~ "test3@example.com"
      refute html =~ "test10@example.com"
      assert html =~ "test11@example.com"

      # Test pagination
      assert index_live
             |> element("nav[aria-label=Pagination]")
             |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      assert html =~ "test1@example.com"
      assert html =~ "test10@example.com"
      refute html =~ "test11@example.com"
      refute html =~ "test15@example.com"
    end

    test "authorized user can see all invitations with pagination", %{
      conn: conn,
      organisation: organisation,
      authorized_user: authorized_user
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert html =~ "Listing Invitations"
      refute html =~ "test1@example.com"
      refute html =~ "test2@example.com"
      refute html =~ "test3@example.com"
      refute html =~ "test10@example.com"
      assert html =~ "test11@example.com"

      # Test pagination
      assert index_live
             |> element("nav[aria-label=Pagination]")
             |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      assert html =~ "test1@example.com"
      assert html =~ "test10@example.com"
      refute html =~ "test11@example.com"
      refute html =~ "test15@example.com"
    end

    test "unauthorized user cannot see invitations", %{
      conn: conn,
      organisation: organisation
    } do
      {:ok, unauthorized_user} = create_user()
      {:ok, group} = create_group(organisation)

      {:ok, _} =
        create_group_membership(organisation, %{group_id: group.id, user_id: unauthorized_user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert html =~ "Listing Invitations"
      refute html =~ "test1@example.com"
      refute html =~ "test20@example.com"
    end

    test "tenant owner can delete invitations", %{
      conn: conn,
      owner: owner,
      organisation: organisation,
      invitations: invitations
    } do
      invitation = Enum.at(invitations, 15)

      {:ok, index_live, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert index_live
             |> element("#delete_invitation_#{invitation.id}")
             |> has_element?()

      html =
        index_live
        |> element("#delete_invitation_#{invitation.id}")
        |> render_click()

      assert html =~ "Invitation deleted successfully"
      refute html =~ invitation.email

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: owner, tenant: organisation)
    end

    test "authorized user can delete invitations", %{
      conn: conn,
      authorized_user: authorized_user,
      organisation: organisation,
      invitations: invitations
    } do
      invitation = Enum.at(invitations, 15)

      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert index_live
             |> element("#delete_invitation_#{invitation.id}")
             |> has_element?()

      html =
        index_live
        |> element("#delete_invitation_#{invitation.id}")
        |> render_click()

      assert html =~ "Invitation deleted successfully"
      refute html =~ invitation.email

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: authorized_user, tenant: organisation)
    end

    test "can sort invitations by inserted_at", %{
      conn: conn,
      owner: owner,
      organisation: organisation,
      invitations: invitations
    } do
      oldest_invitation = List.first(invitations)
      newest_invitation = List.last(invitations)

      {:ok, index_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert html =~ newest_invitation.email
      refute html =~ oldest_invitation.email

      index_live
      |> element("th[phx-click*=\"sort_invitations\"]")
      |> render_click()

      html = render(index_live)
      assert html =~ oldest_invitation.email
      refute html =~ newest_invitation.email
    end
  end

  describe "/organisations/:slug/invitations/new" do
    alias Omedis.Accounts.Group

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

      html =
        view
        |> form("#invitation-form",
          invitation: %{
            email: "test@example.com",
            language: "en",
            groups: %{group.id => true}
          }
        )
        |> render_submit()

      assert_patch(view, ~p"/organisations/#{organisation}/invitations")

      assert html =~ "Invitation created successfully"

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups], tenant: organisation)

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.organisation_id == organisation.id
      assert group.id in Enum.map(invitation.groups, & &1.id)

      # Verify Users group_id is in invitation groups
      {:ok, [users_group]} =
        Group
        |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
        |> Ash.read(authorize?: false, tenant: organisation)

      assert users_group.id in Enum.map(invitation.groups, & &1.id)
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

      html =
        view
        |> form("#invitation-form",
          invitation: %{
            email: "test@example.com",
            language: "en",
            groups: %{group.id => true}
          }
        )
        |> render_submit()

      assert_patch(view, ~p"/organisations/#{organisation}/invitations")

      assert html =~ "Invitation created successfully"

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups], tenant: organisation)

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == authorized_user.id
      assert invitation.organisation_id == organisation.id
      assert group.id in Enum.map(invitation.groups, & &1.id)

      # Verify Users group_id is in invitation groups
      {:ok, [users_group]} =
        Group
        |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
        |> Ash.read(authorize?: false, tenant: organisation)

      assert users_group.id in Enum.map(invitation.groups, & &1.id)
    end

    test "unauthorized user cannot access new invitation page", %{
      conn: conn,
      unauthorized_user: user
    } do
      {:ok, organisation} = create_organisation()

      {:ok, group} =
        create_group(organisation, %{user_id: user.id})

      {:ok, _} = create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Organisation",
          group_id: group.id,
          read: true
        })

      assert {:error, {:live_redirect, %{to: path}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/organisations/#{organisation}/invitations/new")

      assert path == ~p"/organisations/#{organisation}/invitations"
    end

    test "preselects current user's language", %{
      authorized_user: authorized_user,
      conn: conn,
      organisation: organisation
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/invitations/new")

      # Verify the current user's language is preselected
      assert has_element?(view, "input[type='radio'][value='#{authorized_user.lang}'][checked]")
    end

    test "shows validation errors while preserving group selection", %{
      conn: conn,
      group: group,
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/invitations/new")

      html =
        view
        |> form("#invitation-form",
          invitation: %{
            email: "",
            groups: %{group.id => true}
          }
        )
        |> render_change()

      assert html =~ "is required"

      assert html =~
               ~s(type="checkbox" id="invitation_groups_#{group.id}" name="invitation[groups][#{group.id}]" value="true" checked="checked")
    end
  end
end
