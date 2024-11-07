defmodule OmedisWeb.LoginTest do
  use OmedisWeb.ConnCase
  alias Omedis.Accounts.User

  import Phoenix.LiveViewTest

  @valid_create_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "test@gmail.com",
    "gender" => "Male",
    "birthdate" => ~D[1990-01-01],
    "hashed_password" => Bcrypt.hash_pwd_salt("password")
  }

  describe "Tests the Login flow" do
    test "The login form is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      assert has_element?(view, "#basic_user_sign_in_form")
    end

    test "You can log in with valid data", %{conn: conn} do
      {:ok, user} = User.create(@valid_create_params)

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

      conn = submit_form(form, conn)

      assert {:ok, _index_live, _html} = live(conn, ~p"/organisations")
    end
  end
end
