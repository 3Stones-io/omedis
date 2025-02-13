defmodule OmedisWeb.PlaygroundLive.IndexTest do
  use OmedisWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "/playground" do
    test "displays the playground index page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/playground")

      assert html =~ "Playground"
    end

    test "displays the client doctor forms page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/playground")

      {:ok, _lv, html} =
        lv
        |> element("a", "Client Doctor Forms")
        |> render_click()
        |> follow_redirect(conn, ~p"/playground/client-doctor-forms")

      assert html =~ "Create a new client"
    end

    test "displays the time tracking page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/playground")

      {:ok, _lv, html} =
        lv
        |> element("a", "Time Tracking")
        |> render_click()
        |> follow_redirect(conn, ~p"/playground/time-tracking")

      assert html =~ "Time Tracking"
    end
  end
end
