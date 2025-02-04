defmodule OmedisWeb.EditProfileTest do
  use OmedisWeb.ConnCase

  import Phoenix.LiveViewTest
  import Omedis.TestUtils

  alias Omedis.Accounts

  require Ash.Query

  describe "Tests the Edit Profile Feature" do
    test "You can log in with valid data and go to the edit profile page", %{conn: conn} do
      {:ok, user} = create_user()

      assert {:ok, edit_profile_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ "Edit Profile"
      assert html =~ "Edit your profile details"

      assert has_element?(edit_profile_live, "input[name=\"user[first_name]\"]")
      assert has_element?(edit_profile_live, "input[name=\"user[last_name]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[gender]\"]")
      assert has_element?(edit_profile_live, "input[type=\"date\"][name=\"user[birthdate]\"]")
      assert has_element?(edit_profile_live, "select[name=\"user[lang]\"]")
      assert has_element?(edit_profile_live, "button[type=\"submit\"]")
    end

    test "displays user email or name in user menu", %{conn: conn} do
      {:ok, user} = create_user(%{email: "test@gmail.com", first_name: nil, last_name: nil})

      assert {:ok, index_live, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/edit_profile")

      assert html =~ ~s(<span id="user-name">test@gmail.com</span>)

      assert {_, {:redirect, %{to: url}}} =
               index_live
               |> form("#basic_user_edit_profile_form",
                 user: %{"first_name" => "Jane", "last_name" => "Doe"}
               )
               |> render_submit()

      assert {:ok, _index_live, html} =
               conn
               |> log_in_user(user)
               |> live(url)

      assert html =~ ~s(<span id="user-name">Jane Doe</span>)
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

      {:ok, user} = Accounts.get_user_by_email(user.email)

      assert {:ok, _index_live, html} =
               conn
               |> log_in_user(user)
               |> live(url)

      assert html =~ "Edit Profile"
      assert html =~ "Jane"

      assert user.first_name == "Jane"
    end
  end

  test "One cannot delete an account if they are the sole admin", %{conn: conn} do
    {:ok, user} = create_user(%{email: "test@gmail.com"})

    assert {:ok, index_live, _html} =
             conn
             |> log_in_user(user)
             |> live(~p"/edit_profile")

    refute index_live
           |> element("#delete-account-#{user.id}")
           |> has_element?()
  end

  test "You can delete your own account if you are not the only admin", %{conn: conn} do
    {:ok, user} = create_user(%{email: "test@gmail.com"})
    organisation = fetch_users_organisation(user.id)

    create_invitation(organisation, %{
      creator_id: user.id,
      email: "test2@gmail.com"
    })

    {:ok, user_2} = create_user(%{email: "test2@gmail.com"})

    admin_group = admin_group(organisation.id)

    {:ok, _} =
      create_group_membership(organisation, %{group_id: admin_group.id, user_id: user_2.id})

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
