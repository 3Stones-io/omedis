defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.Fixtures

  alias Omedis.Accounts.Invitation

  require Ash.Query

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})

    {:ok, authorized_user} = create_user()
    create_group_user(%{user_id: authorized_user.id, group_id: group.id})

    create_access_right(%{
      resource_name: "Invitation",
      create: true,
      tenant_id: tenant.id,
      group_id: group.id,
      read: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Tenant",
      tenant_id: tenant.id,
      write: true,
      create: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      tenant_id: tenant.id,
      write: true,
      create: true
    })

    {:ok, unauthorized_user} = create_user()
    {:ok, group_2} = create_group()
    create_group_user(%{user_id: unauthorized_user.id, group_id: group_2.id})

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      tenant: tenant,
      unauthorized_user: unauthorized_user
    }
  end

  describe "/tenants/:slug/invitations/new" do
    test "tenant owner can create an invitation", %{
      conn: conn,
      group: group,
      owner: owner,
      tenant: tenant
    } do
      assert {:ok, view, _html} =
               conn
               |> log_in_user(owner)
               |> live(~p"/tenants/#{tenant.slug}/invitations/new")

      view
      |> form("#invitation-form",
        invitation: %{
          email: "test@example.com",
          language: "en",
          groups: %{group.id => true}
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/tenants/#{tenant.slug}")

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups])

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == owner.id
      assert invitation.tenant_id == tenant.id
      assert Enum.map(invitation.groups, & &1.id) == [group.id]
    end

    test "authorized user can create an invitation", %{
      conn: conn,
      group: group,
      authorized_user: authorized_user,
      tenant: tenant
    } do
      assert {:ok, view, _html} =
               conn
               |> log_in_user(authorized_user)
               |> live(~p"/tenants/#{tenant.slug}/invitations/new")

      view
      |> form("#invitation-form",
        invitation: %{
          email: "test@example.com",
          language: "en",
          groups: %{group.id => true}
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/tenants/#{tenant.slug}")

      assert [invitation] =
               Invitation
               |> Ash.Query.filter(email: "test@example.com")
               |> Ash.read!(authorize?: false, load: [:groups])

      assert invitation.email == "test@example.com"
      assert invitation.language == "en"
      assert invitation.creator_id == authorized_user.id
      assert invitation.tenant_id == tenant.id
      assert Enum.map(invitation.groups, & &1.id) == [group.id]
    end

    test "unauthorized user cannot access new invitation page", %{
      conn: conn,
      unauthorized_user: user
    } do
      {:ok, tenant} = create_tenant()

      {:ok, group} =
        create_group(%{tenant_id: tenant.id, user_id: user.id})

      create_group_user(%{user_id: user.id, group_id: group.id})

      create_access_right(%{
        resource_name: "Tenant",
        tenant_id: tenant.id,
        group_id: group.id,
        read: true
      })

      assert {:error, {:live_redirect, %{to: path}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/tenants/#{tenant.slug}/invitations/new")

      assert path == ~p"/tenants/#{tenant.slug}"
    end
  end
end
