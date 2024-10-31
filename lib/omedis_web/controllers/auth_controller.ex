defmodule OmedisWeb.AuthController do
  use OmedisWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
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
      gettext("Username or password is incorrect")
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
      gettext("Something went wrong. Try again.")
    )
    |> redirect(to: "/register")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session()
    |> redirect(to: return_to)
  end
end
