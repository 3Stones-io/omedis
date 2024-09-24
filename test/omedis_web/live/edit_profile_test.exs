defmodule OmedisWeb.EditProfileTest do
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

  describe "Tests the Edit Profile Feature" do
    test "You can log in with valid data and go to the edit profile page", %{conn: conn} do
      {:ok, user} = User.create(@valid_create_params)

      assert {:ok, _index_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ "Edit Profile"
    end

    test "You can change a user's details in the edit profile page", %{conn: conn} do
      {:ok, user} = User.create(@valid_create_params)

      assert {:ok, index_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ "Edit Profile"

      html =
        index_live
        |> form("#basic_user_edit_profile_form", user: %{"first_name" => "Jane"})
        |> render_submit()

      {:ok, user} = User.by_email(@valid_create_params["email"])

      assert user.first_name == "Jane"

      assert html =~ "Profile updated successfully"
    end

    defp log_in_user(conn, user) do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#basic_user_sign_in_form", user: %{email: user.email, password: "password"})

      submit_form(form, conn)
    end
  end
end
