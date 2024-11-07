defmodule OmedisWeb.InvitationLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Omedis.Fixtures
  import Phoenix.LiveViewTest

  alias Omedis.Accounts.User

  @valid_registration_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "test@gmail.com",
    "password" => "12345678",
    "gender" => "Male",
    "birthdate" => ~D[1990-01-01],
    "lang" => "en",
    "daily_start_at" => "09:00:00",
    "daily_end_at" => "17:00:00"
  }

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_membership(%{user_id: owner.id, group_id: group.id})

    {:ok, _} =
      create_access_right(%{
        resource_name: "Invitation",
        create: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        write: true
      })

    {:ok, valid_invitation} =
      create_invitation(%{
        tenant_id: tenant.id,
        creator_id: owner.id
      })

    expired_at = DateTime.utc_now() |> DateTime.add(-7, :day)

    {:ok, expired_invitation} =
      create_invitation(%{
        tenant_id: tenant.id,
        creator_id: owner.id,
        expires_at: expired_at
      })

    %{
      expired_invitation: expired_invitation,
      tenant: tenant,
      owner: owner,
      valid_invitation: valid_invitation
    }
  end

  describe "/tenants/:slug/invitations/:id" do
    test "invitee with a valid invitation can register for an account", %{
      conn: conn,
      tenant: tenant,
      valid_invitation: valid_invitation
    } do
      {:ok, view, _html} =
        live(conn, "/tenants/#{tenant.slug}/invitations/#{valid_invitation.id}")

      form =
        form(
          view,
          "#invitation_user_sign_up_form",
          user: @valid_registration_params
        )

      _conn = submit_form(form, conn)

      assert {:ok, user} = User.by_email(@valid_registration_params["email"])
      assert user.first_name == @valid_registration_params["first_name"]
    end

    test "form errors are displayed", %{
      conn: conn,
      tenant: tenant,
      valid_invitation: valid_invitation
    } do
      {:ok, view, _html} =
        live(conn, "/tenants/#{tenant.slug}/invitations/#{valid_invitation.id}")

      html =
        view
        |> form("#invitation_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "page is displayed in the correct language", %{
      conn: conn,
      tenant: tenant,
      owner: owner
    } do
      {:ok, invitation} =
        create_invitation(%{
          tenant_id: tenant.id,
          creator_id: owner.id,
          language: "fr"
        })

      {:ok, _view, html} =
        live(conn, "/tenants/#{tenant.slug}/invitations/#{invitation.id}")

      assert html =~ "Date de naissance"
      assert html =~ "Utilisez une adresse permanente où vous pouvez recevoir du courrier."
    end

    test "invitee with an expired invitation is redirected", %{
      conn: conn,
      expired_invitation: expired_invitation,
      tenant: tenant
    } do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, "/tenants/#{tenant.slug}/invitations/#{expired_invitation.id}")

      assert path == "/"
      assert flash["error"] == "Invitation is not valid"
    end
  end
end
