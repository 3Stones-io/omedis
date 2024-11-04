defmodule OmedisWeb.InvitationLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.Fixtures

  describe "New Invitation" do
    setup do
      tenant = create_tenant!()
      group = create_group!(tenant_id: tenant.id)

      owner = get_tenant_owner(tenant)

      regular_user = create_user!()
      create_group_user!(user_id: regular_user.id, group_id: group.id)

      unauthorized_user = create_user!()

      authorized_user = create_user!()
      create_group_user!(user_id: authorized_user.id, group_id: group.id)

      create_access_right!(
        resource_name: "Invitation",
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      )

      %{
        tenant: tenant,
        group: group,
        owner: owner,
        regular_user: regular_user,
        unauthorized_user: unauthorized_user,
        authorized_user: authorized_user
      }
    end

    test "authorized user can access new invitation page", %{
      conn: conn,
      tenant: tenant,
      authorized_user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, view, _html} =
        live(conn, ~p"/tenants/#{tenant.slug}/invitations")

      assert has_element?(view, "h1", "New Invitation")
    end

    test "unauthorized user cannot access new invitation page", %{
      conn: conn,
      tenant: tenant,
      unauthorized_user: user
    } do
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/tenants/#{tenant.slug}/invitations")
    end

    test "creates invitation with valid data", %{
      conn: conn,
      tenant: tenant,
      group: group,
      owner: owner
    } do
      conn = log_in_user(conn, owner)
      {:ok, view, _html} = live(conn, ~p"/tenants/#{tenant.slug}/invitations")

      valid_attrs = %{
        "email" => "test@example.com",
        "language" => "en",
        "group_ids" => [group.id]
      }

      view
      |> form("#invitation-form", invitation: valid_attrs)
      |> render_submit()

      assert_redirected(view, ~p"/tenants/#{tenant.slug}")
    end

    test "renders errors with invalid data", %{
      conn: conn,
      tenant: tenant,
      owner: owner
    } do
      conn = log_in_user(conn, owner)
      {:ok, view, _html} = live(conn, ~p"/tenants/#{tenant.slug}/invitations")

      invalid_attrs = %{
        "email" => "invalid-email",
        "language" => "",
        "group_ids" => []
      }

      html =
        view
        |> form("#invitation-form", invitation: invalid_attrs)
        |> render_change()

      assert html =~ "is invalid"
    end
  end
end
