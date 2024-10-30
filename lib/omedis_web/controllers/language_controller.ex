defmodule OmedisWeb.LanguageController do
  use OmedisWeb, :controller

  def update(conn, %{"lang" => lang}) do
    conn
    |> put_session(:language, lang)
    |> put_resp_cookie("locale", lang)
    |> configure_session(renew: true)
    |> redirect(to: return_to(conn))
  end

  defp return_to(conn) do
    case get_req_header(conn, "referer") |> List.first() do
      nil -> ~p"/register"
      referer -> URI.parse(referer).path || ~p"/register"
    end
  end
end
