defmodule OmedisWeb.InvitationLive.ShowTest do
  use OmedisWeb.ConnCase, async: true

  import Omedis.Fixtures
  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.User

  @valid_registration_params %{
    "email" => "test@gmail.com",
    "password" => "12345678"
  }

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "Invitation",
        create: true,
        group_id: group.id,
        read: true,
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    {:ok, valid_invitation} =
      create_invitation(organisation, %{
        creator_id: owner.id,
        email: "test@gmail.com"
      })

    {:ok, invitation} =
      create_invitation(organisation, %{
        creator_id: owner.id
      })

    expired_invitation = Invitation.expire!(invitation, actor: owner)

    %{
      expired_invitation: expired_invitation,
      organisation: organisation,
      owner: owner,
      valid_invitation: valid_invitation
    }
  end

  describe "/organisations/:slug/invitations/:id" do
    test "invitee with a valid invitation can register for an account", %{
      conn: conn,
      organisation: organisation,
      valid_invitation: valid_invitation
    } do
      {:ok, view, _html} =
        live(conn, ~p"/organisations/#{organisation}/invitations/#{valid_invitation.id}")

      form =
        form(
          view,
          "#invitation_user_sign_up_form",
          user: @valid_registration_params
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"

      assert {:ok, user} = User.by_email(@valid_registration_params["email"])
      assert Ash.CiString.value(user.email) == @valid_registration_params["email"]

      # Verify invitation was updated
      {:ok, updated_invitation} = Invitation.by_id(valid_invitation.id)

      assert updated_invitation.user_id == user.id
    end

    test "form errors are displayed", %{
      conn: conn,
      organisation: organisation,
      valid_invitation: valid_invitation
    } do
      {:ok, view, _html} =
        live(conn, ~p"/organisations/#{organisation}/invitations/#{valid_invitation.id}")

      html =
        view
        |> form("#invitation_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "page is displayed in the correct language", %{
      conn: conn,
      organisation: organisation,
      owner: owner
    } do
      {:ok, invitation} =
        create_invitation(organisation, %{
          creator_id: owner.id,
          language: "fr"
        })

      {:ok, _view, html} =
        live(conn, ~p"/organisations/#{organisation}/invitations/#{invitation.id}")

      assert html =~ "Mot de passe"
      assert html =~ "Utilisez une adresse permanente où vous pouvez recevoir du courrier."
    end

    test "shows error for invalid invitation ID", %{
      conn: conn,
      organisation: organisation
    } do
      invalid_id = Ash.UUID.generate()

      {:ok, conn} =
        conn
        |> live(~p"/organisations/#{organisation}/invitations/#{invalid_id}")
        |> follow_redirect(conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invitation expired or not found"
      assert conn.request_path == "/login"
    end

    test "shows error when user is already registered", %{
      conn: conn,
      organisation: organisation,
      valid_invitation: invitation
    } do
      # First create a user with the invitation email
      {:ok, _user} = create_user(%{email: invitation.email})

      {:ok, conn} =
        conn
        |> live(~p"/organisations/#{organisation}/invitations/#{invitation.id}")
        |> follow_redirect(conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "User already registered"
      assert conn.request_path == "/login"
    end
  end
end
