defmodule OmedisWeb.AuthController do
  use OmedisWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to) || get_return_to(activity)

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> maybe_show_flash_message(activity)
    |> redirect(to: return_to)
  end

  def failure(
        conn,
        {:password, :sign_in},
        %AshAuthentication.Errors.AuthenticationFailed{} = reason
      ) do
    conn
    |> assign(:errors, reason)
    |> put_flash(
      :error,
      dgettext("auth", "Username or password is incorrect")
    )
    |> redirect(to: "/login")
  end

  def failure(
        conn,
        {:password, :register},
        reason
      ) do
    conn
    |> assign(:errors, reason)
    |> put_flash(
      :error,
      dgettext("auth", "Something went wrong. Try again.")
    )
    |> redirect(to: "/register")
  end

  def failure(
        conn,
        {:password, :reset},
        reason
      ) do
    conn
    |> assign(:errors, reason)
    |> put_flash(
      :error,
      dgettext("auth", "Reset password link is invalid or it has expired.")
    )
    |> redirect(to: "/login")
  end

  def failure(
        conn,
        _action,
        reason
      ) do
    conn
    |> assign(:errors, reason)
    |> put_flash(
      :error,
      dgettext("auth", "Something went wrong. Try again.")
    )
    |> redirect(to: "/login")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session()
    |> redirect(to: return_to)
  end

  defp get_return_to(action) when action in [{:password, :reset_request}, {:password, :reset}],
    do: ~p"/login"

  defp get_return_to(_action), do: ~p"/edit_profile"

  defp maybe_show_flash_message(conn, {:password, :reset_request}) do
    put_flash(
      conn,
      :info,
      dgettext(
        "auth",
        "If your email is in our system, you will receive instructions to reset your password shortly."
      )
    )
  end

  defp maybe_show_flash_message(conn, {:password, :reset}) do
    put_flash(
      conn,
      :info,
      dgettext(
        "auth",
        "Password reset successful. Please log in with your new password."
      )
    )
  end

  defp maybe_show_flash_message(conn, _activity), do: conn
end
