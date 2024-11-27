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
      {:ok, view, _html} =
        live(conn, ~p"/organisations/#{organisation}/invitations/#{valid_invitation.id}")

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
      assert_raise Ash.Error.Query.NotFound, fn ->
        live(conn, ~p"/organisations/#{organisation}/invitations/#{expired_invitation.id}")
      end
    end
  end
end
