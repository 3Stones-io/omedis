defmodule OmedisWeb.ResetPasswordLiveTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AshAuthentication.Info
  alias AshAuthentication.Strategy.Password
  alias Omedis.Accounts.User

  setup do
    {:ok, user} = create_user()

    %{user: user}
  end

  describe "/password-reset/:token" do
    test "renders reset password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/password-reset/token")

      assert html =~ "Reset Password"
    end

    test "renders form errors", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset/token")

      html =
        lv
        |> form("#reset-password-form", user: %{"password" => "ne"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "does not reset password if token is invalid", %{conn: conn, user: user} do
      strategy =
        Info.strategy_for_action!(User, :password_reset_with_password)

      {:ok, invalid_token} = Password.reset_token_for(strategy, user)

      {:ok, lv, _html} = live(conn, ~p"/password-reset/#{invalid_token}")

      form = form(lv, "#reset-password-form", user: %{"password" => "new_password"})

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired."
    end

    test "reset password if token is valid", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset")

      form =
        form(lv, "#reset-password-form", user: %{"email" => Ash.CiString.value(user.email)})

      render_submit(form)
      follow_trigger_action(form, conn)

      assert_received {:email, %Swoosh.Email{text_body: text_body}}

      %{"url" => url} = Regex.named_captures(~r/(?<url>http[^\s]+)/, text_body)

      [_, token] = String.split(url, "/password-reset/", parts: 2, trim: true)

      {:ok, lv, _html} = live(conn, ~p"/password-reset/#{token}")

      form =
        form(lv, "#reset-password-form",
          user: %{"password" => "new_password", "reset_token" => token}
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"

      conn = get(conn, ~p"/edit_profile")
      response = html_response(conn, 200)
      assert response =~ "Password reset successful."
    end
  end
end
