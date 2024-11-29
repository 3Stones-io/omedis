defmodule OmedisWeb.RegisterTest do
  use OmedisWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  describe "/register" do
    test "a user can register for an account", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      form =
        form(view, "#basic_user_sign_up_form",
          user: %{
            email: "test@gmail.com",
            password: "12345678"
          }
        )

      _conn = submit_form(form, conn)

      assert {:ok, user} = User.by_email("test@gmail.com")
      assert [organisation] = Ash.read!(Organisation, actor: user)
      assert organisation.owner_id == user.id
      assert organisation.name == "test@gmail.com"
    end

    test "render form errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")

      html =
        view
        |> form("#basic_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "cannot submit a form with errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      html =
        view
        |> form("#basic_user_sign_up_form",
          user: %{
            email: "test@gmail.com",
            password: "12"
          }
        )
        |> render_submit()

      assert html =~ "length must be greater than or equal to 8"
    end
  end
end
