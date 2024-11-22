defmodule OmedisWeb.EditProfileTest do
  use OmedisWeb.ConnCase
  alias Omedis.Accounts.User

  import Phoenix.LiveViewTest

  describe "Tests the Edit Profile Feature" do
    test "You can log in with valid data and go to the edit profile page", %{conn: conn} do
      {:ok, user} = create_user()

      assert {:ok, _index_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ "Edit Profile"
    end

    test "You can change a user's details in the edit profile page", %{conn: conn} do
      {:ok, user} = create_user()

      assert {:ok, index_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ "Edit Profile"

      assert {_,
              {:redirect,
               %{
                 to: url,
                 flash: _
               }}} =
               index_live
               |> form("#basic_user_edit_profile_form", user: %{"first_name" => "Jane"})
               |> render_submit()

      {:ok, user} = User.by_email(user.email)

      assert {:ok, _index_live, html} =
               conn
               |> log_in_user(user)
               |> live(url)

      assert html =~ "Edit Profile"
      assert html =~ "Jane"

      assert user.first_name == "Jane"
    end
  end

  test "You can delete your own account", %{conn: conn} do
    {:ok, user} = create_user()
    {:ok, _} = create_organisation(%{owner_id: user.id})

    assert {:ok, index_live, _html} =
             conn
             |> log_in_user(user)
             |> live(~p"/edit_profile")

    assert {:error, {:redirect, %{to: url}}} =
             index_live
             |> element("#delete-account-#{user.id}")
             |> render_click()

    assert url == ~p"/"

    # Verify user is logged out by attempting to access a protected route
    assert {:error, {:redirect, %{to: "/login"}}} =
             live(conn, ~p"/edit_profile")
  end

  test "unauthorised users cannot delete an account", %{conn: conn} do
    {:ok, user} = create_user()
    {:ok, _} = create_organisation(%{owner_id: user.id})
    {:ok, unauthorised_user} = create_user()

    assert {:ok, index_live, _html} =
             conn
             |> log_in_user(unauthorised_user)
             |> live(~p"/edit_profile")

    refute index_live
           |> element("#delete-account-#{user.id}")
           |> has_element?()
  end
end
