defmodule OmedisWeb.LoginTest do
  use OmedisWeb.ConnCase

  alias Omedis.Accounts

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  require Ash.Query

  @valid_create_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "test@gmail.com",
    "gender" => "Male",
    "birthdate" => ~D[1990-01-01],
    "hashed_password" => Bcrypt.hash_pwd_salt("password")
  }

  describe "/login" do
    test "The login form is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      assert has_element?(view, "#basic_user_sign_in_form")
    end

    test "You can log in with valid data", %{conn: conn} do
      {:ok, user} = Accounts.create_user(@valid_create_params)

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"
    end

    test "redirects to the edit profile page if no other return_to path is set", %{conn: conn} do
      {:ok, user} =
        @valid_create_params
        |> Map.put(:email, "test@gmail.com")
        |> Accounts.create_user()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

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

    test "shows errors when wrong credentials are entered", %{conn: conn} do
      {:ok, user} = Accounts.create_user(@valid_create_params)

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form",
          user: %{email: user.email, password: "invalid_password"}
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/login"

      conn = get(conn, "/login")
      response = html_response(conn, 200)
      assert response =~ "Username or password is incorrect"
    end

    test "redirects to forgot password page when the forgot password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      html =
        lv
        |> element("#forgot-password-link")
        |> render_click()

      assert html =~ "Forgot your password?"

      assert_patch(lv, ~p"/password-reset")
    end
  end

  describe "/password-reset" do
    setup do
      {:ok, user} = create_user()

      %{user: user}
    end

    test "renders forgot password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/password-reset")

      assert html =~ "Forgot your password?"
      assert html =~ "Send reset link"
    end

    test "redirects if the user is logged in", %{conn: conn, user: user} do
      result =
        conn
        |> log_in_user(user)
        |> live(~p"/password-reset")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "sends a request for a new reset password token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset")

      form =
        form(lv, "#request-password-reset-form",
          user: %{"email" => Ash.CiString.value(user.email)}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/login"

      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "If your email is in our system"

      assert_email_sent(subject: "Omedis | Reset your password")

      assert {:ok, [token]} =
               Accounts.Token
               |> Ash.Query.filter(subject: AshAuthentication.user_to_subject(user))
               |> Ash.read()

      assert token.purpose == "user"
    end

    test "does not send reset password token if the email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset")

      form = form(lv, "#request-password-reset-form", user: %{"email" => "invalid@example.com"})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/login"

      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "If your email is in our system"

      assert {:ok, []} = Ash.read(Accounts.Token)
    end
  end

  describe "/sign-out" do
    test "user can sign out", %{conn: conn} do
      {:ok, user} = Accounts.create_user(@valid_create_params)

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/auth/user/sign-out")

      assert redirected_to(conn) == ~p"/"
    end
  end
end
