defmodule OmedisWeb.ForgotPasswordLiveTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Omedis.Accounts

  require Ash.Query

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
        form(lv, "#reset-password-form", user: %{"email" => Ash.CiString.value(user.email)})

      render_submit(form)
      conn = follow_trigger_action(form, conn)

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

      form = form(lv, "#reset-password-form", user: %{"email" => "invalid@example.com"})

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/login"

      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "If your email is in our system"

      assert {:ok, []} = Ash.read(Accounts.Token)
    end
  end
end
