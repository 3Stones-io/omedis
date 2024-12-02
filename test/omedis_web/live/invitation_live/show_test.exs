defmodule OmedisWeb.InvitationLive.ShowTest do
  use OmedisWeb.ConnCase, async: false

  import Omedis.Fixtures
  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.User

  setup do
    {:ok, _pid} = start_supervised(Omedis.Accounts.InvitationUserLinker)
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{user_id: owner.id, group_id: group.id})

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "Invitation",
        create: true,
        group_id: group.id,
        read: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

    {:ok, valid_invitation} =
      create_invitation(organisation, %{
        creator_id: owner.id
      })

    expired_at = DateTime.utc_now() |> DateTime.add(-7, :day)

    {:ok, expired_invitation} =
      create_invitation(organisation, %{
        creator_id: owner.id,
        expires_at: expired_at
      })

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
      :ok = OmedisWeb.Endpoint.subscribe("user:created")

      {:ok, view, _html} =
        live(conn, ~p"/organisations/#{organisation}/invitations/#{valid_invitation.id}")

      valid_registration_params = %{
        "first_name" => "Testabc",
        "last_name" => "Userxyz",
        "password" => "12345678",
        "gender" => "Male",
        "birthdate" => ~D[1990-01-01],
        "lang" => "en",
        "daily_start_at" => "09:00:00",
        "daily_end_at" => "17:00:00"
      }

      form =
        form(
          view,
          "#invitation_user_sign_up_form",
          user: valid_registration_params
        )

      html = render_submit(form)

      created_user_email = Ash.CiString.new(valid_invitation.email)

      # TODO: Figure out why we don't get a broadcast for the created user
      assert_broadcast "register_with_password", %Ash.Notifier.Notification{
        data: %{email: ^created_user_email}
      }

      assert html =~ "Testabc"
      assert html =~ "Userxyz"

      assert {:ok, user} = User.by_email(valid_invitation.email)
      assert user.first_name == valid_registration_params["first_name"]

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

      assert html =~ "Date de naissance"
      assert html =~ "Utilisez une adresse permanente où vous pouvez recevoir du courrier."
    end

    test "invitee with an expired invitation sees a not found page", %{
      conn: conn,
      expired_invitation: expired_invitation,
      organisation: organisation
    } do
      {:ok, conn} =
        conn
        |> live(~p"/organisations/#{organisation}/invitations/#{expired_invitation.id}")
        |> follow_redirect(conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invitation expired"
      assert conn.request_path == "/login"
    end
  end
end
