defmodule OmedisWeb.ForgotPasswordLiveTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      # TODO: Confirm that email was sent
    end
  end
end
