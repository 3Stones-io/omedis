defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Invitation

  describe "/tenants/:slug/invitations" do
    setup do
      {:ok, owner} = create_user()
      {:ok, user_2} = create_user()

      {:ok, tenant} =
        create_tenant(%{name: "Test Tenant", slug: "test-tenant", owner_id: owner.id})

      {:ok, group} = create_group()
      {:ok, _} = create_group_membership(%{group_id: group.id, user_id: user_2.id})

      # Create invitations (15 for owner, 5 for user_2)
      invitations =
        for i <- 1..20 do
          {:ok, invitation} =
            create_invitation(%{
              email: "test#{i}@example.com",
              tenant_id: tenant.id,
              creator_id: if(Enum.random([true, false]), do: owner.id, else: user_2.id),
              language: "en"
            })

          invitation
        end

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          write: true,
          resource_name: "Invitation"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          resource_name: "Tenant",
          write: true
        })

      %{
        group: group,
        invitations: invitations,
        owner: owner,
        tenant: tenant,
        user_2: user_2
      }
    end

    test "tenant owner can see all invitations with pagination", %{
      conn: conn,
      owner: owner,
      tenant: tenant
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant}/invitations")

      assert html =~ "Listing Invitations"
      assert html =~ "test1@example.com"
      assert html =~ "test2@example.com"
      assert html =~ "test3@example.com"
      assert html =~ "test10@example.com"
      refute html =~ "test11@example.com"

      # Test pagination
      assert index_live
             |> element("nav[aria-label=Pagination]")
             |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      refute html =~ "test1@example.com"
      refute html =~ "test10@example.com"
      assert html =~ "test11@example.com"
      assert html =~ "test15@example.com"
    end

    test "authorized user can see only invitations they have access to", %{
      conn: conn,
      tenant: tenant,
      user_2: authorized_user
    } do
      {:ok, index_live, html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant}/invitations")

      assert html =~ "Listing Invitations"
      assert html =~ "test1@example.com"
      assert html =~ "test2@example.com"
      assert html =~ "test3@example.com"
      assert html =~ "test10@example.com"
      refute html =~ "test11@example.com"

      # Test pagination
      assert index_live
             |> element("nav[aria-label=Pagination]")
             |> has_element?()

      # Navigate to the second page
      index_live
      |> element("nav[aria-label=Pagination] a", "2")
      |> render_click()

      html = render(index_live)
      refute html =~ "test1@example.com"
      refute html =~ "test10@example.com"
      assert html =~ "test11@example.com"
      assert html =~ "test15@example.com"
    end

    test "unauthorized user cannot see invitations", %{
      conn: conn,
      tenant: tenant
    } do
      {:ok, unauthorized_user} = create_user()
      {:ok, group} = create_group()
      {:ok, _} = create_group_membership(%{group_id: group.id, user_id: unauthorized_user.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          tenant_id: tenant.id,
          read: true,
          resource_name: "Tenant"
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(unauthorized_user)
        |> live(~p"/tenants/#{tenant}/invitations")

      assert html =~ "Listing Invitations"
      refute html =~ "test1@example.com"
      refute html =~ "test20@example.com"
    end

    test "tenant owner can delete invitations", %{
      conn: conn,
      owner: owner,
      tenant: tenant,
      invitations: invitations
    } do
      invitation = Enum.at(invitations, 0)

      {:ok, index_live, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/tenants/#{tenant}/invitations")

      assert index_live
             |> element("#invitations")
             |> render() =~ invitation.email

      index_live
      |> element("#delete_invitation_#{invitation.id}")
      |> render_click()

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: owner, tenant: tenant)
    end

    test "authorized user can delete invitations", %{
      conn: conn,
      user_2: authorized_user,
      tenant: tenant,
      invitations: invitations
    } do
      invitation = Enum.at(invitations, 1)

      {:ok, index_live, _html} =
        conn
        |> log_in_user(authorized_user)
        |> live(~p"/tenants/#{tenant}/invitations")

      assert index_live
             |> element("#invitations")
             |> render() =~ invitation.email

      index_live
      |> element("#delete_invitation_#{invitation.id}")
      |> render_click()

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: authorized_user, tenant: tenant)
    end
  end
end
