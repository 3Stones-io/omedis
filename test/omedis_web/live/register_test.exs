defmodule OmedisWeb.RegisterTest do
  use OmedisWeb.ConnCase
  alias Omedis.Accounts.User

  import Phoenix.LiveViewTest

  @valid_registration_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "test@gmail.com",
    "password" => "12345678",
    "gender" => "Male",
    "birthdate" => ~D[1990-01-01]
  }

  describe "Tests the Registration flow" do
    test "The registration form is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")
    end

    test "Once we make changes to the registration form , we see any errors if they are there", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/register")

      html =
        view
        |> form("#basic_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "Last Name is required"
      assert html =~ "First Name is required"
    end

    test "You can sign in with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      {:error, _} = User.by_email(@valid_registration_params["email"])

      html =
        view
        |> form("#basic_user_sign_up_form", user: @valid_registration_params)
        |> render_change()

      refute html =~ "Password is required"
      refute html =~ "First Name is required"

      {:ok, _index_live, _html} =
        conn
        |> sign_in_user(@valid_registration_params)
        |> live(~p"/tenants")

      {:ok, user} = User.by_email(@valid_registration_params["email"])

      assert user.first_name == @valid_registration_params["first_name"]
    end

    defp sign_in_user(conn, attributes) do
      {:ok, lv, _html} = live(conn, ~p"/register")

      form =
        form(lv, "#basic_user_sign_up_form", user: attributes)

      submit_form(form, conn)
    end
  end
end
