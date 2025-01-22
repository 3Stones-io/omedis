defmodule OmedisWeb.RegisterTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  alias Omedis.Accounts
  alias Omedis.Invitations

  @valid_registration_params %{
    email: "test@gmail.com",
    password: "12345678"
  }

  describe "/register" do
    test "a user can register for an account and an organisation is created",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      form =
        form(view, "#basic_user_sign_up_form",
          user: %{
            email: "test@gmail.com",
            password: "12345678"
          }
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ "test@gmail.com"

      assert {:ok, user} = Accounts.get_user_by_email("test@gmail.com")
      assert [organisation] = Ash.read!(Accounts.Organisation, actor: user)
      assert organisation.owner_id == user.id
      assert organisation.name == "test@gmail.com"
      assert user.current_organisation_id == organisation.id
    end

    test "redirects to the edit profile page if no other return_to path is set", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      form =
        form(view, "#basic_user_sign_up_form",
          user: %{
            email: "test@gmail.com",
            password: "12345678"
          }
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"

      assert {:ok, edit_profile_live, html} = live(conn, ~p"/edit_profile")
      assert html =~ "Edit your profile details"

      assert has_element?(edit_profile_live, "input[name=\"user[first_name]\"]")
      assert has_element?(edit_profile_live, "input[name=\"user[last_name]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[gender]\"]")
      assert has_element?(edit_profile_live, "input[type=\"date\"][name=\"user[birthdate]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[lang]\"]")
      assert has_element?(edit_profile_live, "button[type=\"submit\"]")
    end

    test "cannot register with existing email", %{conn: conn} do
      {:ok, user} = create_user()

      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      form =
        form(view, "#basic_user_sign_up_form",
          user: %{
            email: user.email,
            password: "12345678"
          }
        )

      conn = submit_form(form, conn)
      assert conn.status == 302
      assert conn.assigns.errors
    end

    test "render form errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      html =
        view
        |> form("#basic_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "cannot submit a form with errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      html =
        view
        |> form("#basic_user_sign_up_form",
          user: %{
            email: "test@gmail.com",
            password: "12"
          }
        )
        |> render_submit()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "user can select language", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#language-form")

      form = form(view, "#language-form", %{"lang" => "de"})
      conn = submit_form(form, conn)

      {:ok, _view, html} = live(conn, ~p"/register")

      assert html =~ "Registrieren"
      assert html =~ "Passwort"

      assert html =~
               "Verwenden Sie eine permanente E-Mail-Adresse, unter der Sie E-Mails empfangen können."
    end

    test "updates the associated invitation when user is created", %{
      conn: conn
    } do
      {:ok, user} = create_user()
      organisation = fetch_users_organisation(user.id)
      {:ok, invitation} = create_invitation(organisation, %{email: "test@user.com"})

      assert {:error, _} = Accounts.get_user_by_email("test@user.com")

      {:ok, view, _html} = live(conn, "/register")

      view
      |> form("#basic_user_sign_up_form")
      |> render_change(user: %{current_organisation_id: organisation.id})

      updated_params = Map.put(@valid_registration_params, "email", "test@user.com")

      form =
        form(view, "#basic_user_sign_up_form", user: updated_params)

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      {:ok, _index_live, _html} = live(conn, ~p"/edit_profile")

      assert {:ok, user} = Accounts.get_user_by_email("test@user.com")

      {:ok, updated_invitation} = Invitations.get_invitation_by_id(invitation.id)

      assert updated_invitation.user_id == user.id
    end
  end
end
