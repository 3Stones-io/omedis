defmodule OmedisWeb.ResetPasswordLiveTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AshAuthentication.Info
  alias AshAuthentication.Strategy.Password
  alias Omedis.Accounts

  setup do
    {:ok, user} = create_user()

    token = reset_password_token(user)

    %{user: user, token: token}
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

    test "does not reset password if token is invalid", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset/#{token}")

      form = form(lv, "#reset-password-form", user: %{"password" => "new_password"})

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      # Chech flash in HTML
      assert redirected_to(conn) == ~p"/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired."
    end
  end

  # TODO: Generate a valid token?
  defp reset_password_token(user) do
    strategy = Info.strategy_for_action!(Accounts.User, :password_reset_with_password)
    {:ok, token} = Password.reset_token_for(strategy, user)
    token
  end
end
