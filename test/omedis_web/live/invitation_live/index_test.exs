defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Invitation

  setup do
    {:ok, owner} = create_user()
    {:ok, user_2} = create_user()

    {:ok, organisation} =
      create_organisation(%{
        name: "Test Organisation",
        slug: "test-organisation",
        owner_id: owner.id
      })

    {:ok, group} = create_group()
    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: user_2.id})

    # Create invitations (15 for owner, 5 for user_2)
    invitations =
      for i <- 1..20 do
        {:ok, invitation} =
          create_invitation(%{
            email: "test#{i}@example.com",
            organisation_id: organisation.id,
            creator_id: if(Enum.random([true, false]), do: owner.id, else: user_2.id),
            language: "en"
          })

        invitation
        |> Ash.Changeset.for_update(:update, %{inserted_at: time_after(-i * 12_000)},
          authorize?: false
        )
        |> Ash.update!()
      end

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        organisation_id: organisation.id,
        read: true,
        write: true,
        resource_name: "Invitation"
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        organisation_id: organisation.id,
        read: true,
        resource_name: "Organisation",
        write: true
      })

    %{
      group: group,
      invitations: invitations,
      owner: owner,
      organisation: organisation,
      user_2: user_2
    }
  end

  describe "/organisations/:slug/invitations" do
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
      user_2: authorized_user
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
      {:ok, group} = create_group()
      {:ok, _} = create_group_membership(%{group_id: group.id, user_id: unauthorized_user.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          organisation_id: organisation.id,
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
             |> element("#invitations")
             |> render() =~ invitation.email

      index_live
      |> element("#delete_invitation_#{invitation.id}")
      |> render_click()

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: owner, tenant: organisation)
    end

    test "authorized user can delete invitations", %{
      conn: conn,
      user_2: authorized_user,
      organisation: organisation,
      invitations: invitations
    } do
      invitation = Enum.at(invitations, 15)

      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/organisations/#{organisation}/invitations")

      assert index_live
             |> element("#invitations")
             |> render() =~ invitation.email

      index_live
      |> element("#delete_invitation_#{invitation.id}")
      |> render_click()

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
end
