defmodule OmedisWeb.LoginTest do
  use OmedisWeb.ConnCase

  alias Omedis.Accounts

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
      {:ok, user} = Accounts.create_user(@valid_create_params)

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

      conn = submit_form(form, conn)

      assert {:ok, _index_live, _html} = live(conn, ~p"/edit_profile")
    end

    test "redirects to the edit profile page if no other return_to path is set", %{conn: conn} do
      {:ok, user} =
        @valid_create_params
        |> Map.put(:email, "test@gmail.com")
        |> Accounts.create_user()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/edit_profile"

      assert {:ok, edit_profile_live, html} = live(conn, ~p"/edit_profile")
      assert html =~ "Edit your profile details"

      assert has_element?(edit_profile_live, "input[name=\"user[first_name]\"]")
      assert has_element?(edit_profile_live, "input[name=\"user[last_name]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[gender]\"]")
      assert has_element?(edit_profile_live, "input[type=\"date\"][name=\"user[birthdate]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[lang]\"]")
      assert has_element?(edit_profile_live, "button[type=\"submit\"]")
    end

    test "shows errors when wrong credentials are entered", %{conn: conn} do
      {:ok, user} = Accounts.create_user(@valid_create_params)

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form",
          user: %{email: user.email, password: "invalid_password"}
        )

      conn = submit_form(form, conn)

      assert {:ok, _index_live, html} = live(conn, ~p"/login")

      assert html =~ "Username or password is incorrect"
    end
  end
end
