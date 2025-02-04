defmodule OmedisWeb.ResetPasswordLiveTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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

    test "does not reset password if token is invalid", %{conn: conn} do
      invalid_token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY3QiOiJwYXNzd29yZF9yZXNldF93aXRoX3Bhc3N3b3JkIiwiYXVkIjoifj4gNC4zIiwiZXhwIjoxNzM4NTcxNzQxLCJpYXQiOjE3MzgzMTI1NDEsImlzcyI6IkFzaEF1dGhlbnRpY2F0aW9uIHY0LjMuOSIsImp0aSI6IjMwZnJrMnZrc2k1c3BoMTcyYzAwMGNxMSIsIm5iZiI6MTczODMxMjU0MSwic3ViIjoidXNlcj9pZD1kNjcwOTEzNy1iMGNkLTQyZmEtYmVmYy05YjI4NTAwNjgzOTMifQ.C2TIHvFkGukyJDVkyonbo2jkh1I0anfdd71EBaT__M8"

      {:ok, lv, _html} = live(conn, ~p"/password-reset/#{invalid_token}")

      form =
        form(lv, "#reset-password-form",
          user: %{"password" => "new_password", "reset_token" => invalid_token}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired."
    end

    test "reset password if token is valid", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/password-reset")

      form =
        form(lv, "#request-password-reset-form",
          user: %{"email" => Ash.CiString.value(user.email)}
        )

      submit_form(form, conn)

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
