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
    "birthdate" => ~D[1990-01-01],
    "lang" => "en",
    "daily_start_at" => "09:00:00",
    "daily_end_at" => "17:00:00"
  }

  @valid_organisation_params %{
    "name" => "Test Organisation",
    "street" => "123 Test St",
    "zip_code" => "12345",
    "city" => "Test City",
    "country" => "Test Country",
    "slug" => "test-organisation"
  }

  setup do
    {:ok, organisation} = create_organisation(@valid_organisation_params)
    {:ok, %{tenant: organisation}}
  end

  describe "Tests the Registration flow" do
    test "The registration form is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")
    end

    test "Form fields are disabled until a organisation is selected", %{
      conn: conn,
      tenant: organisation
    } do
      {:ok, view, _html} = live(conn, "/register")

      assert view |> element("#user_email") |> render() =~ "disabled"
      assert view |> element("#user_first_name") |> render() =~ "disabled"
      assert view |> element("#user_last_name") |> render() =~ "disabled"
      assert view |> element("#user_password") |> render() =~ "disabled"
      assert view |> element("#user_gender") |> render() =~ "disabled"
      assert view |> element("#user_birthdate") |> render() =~ "disabled"
      assert view |> element("#user_daily_start_at") |> render() =~ "disabled"
      assert view |> element("#user_daily_end_at") |> render() =~ "disabled"

      view
      |> form("#basic_user_sign_up_form")
      |> render_change(user: %{current_organisation_id: organisation.id})

      refute view |> element("#user_email") |> render() =~ "disabled"
      refute view |> element("#user_first_name") |> render() =~ "disabled"
      refute view |> element("#user_last_name") |> render() =~ "disabled"
      refute view |> element("#user_password") |> render() =~ "disabled"
      refute view |> element("#user_gender") |> render() =~ "disabled"
      refute view |> element("#user_birthdate") |> render() =~ "disabled"
      refute view |> element("#user_daily_start_at") |> render() =~ "disabled"
      refute view |> element("#user_daily_end_at") |> render() =~ "disabled"
    end

    test "Once we make changes to the registration form, we see any errors if they are there", %{
      conn: conn,
      tenant: organisation
    } do
      {:ok, view, _html} = live(conn, "/register")

      view
      |> form("#basic_user_sign_up_form")
      |> render_change(user: %{current_organisation_id: organisation.id})

      html =
        view
        |> form("#basic_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "You can sign in with valid data", %{conn: conn, tenant: organisation} do
      {:ok, view, _html} = live(conn, "/register")

      {:error, _} = User.by_email(@valid_registration_params["email"])

      view
      |> form("#basic_user_sign_up_form")
      |> render_change(user: %{current_organisation_id: organisation.id})

      params =
        @valid_registration_params
        |> Map.replace("first_name", "Mary")
        |> Map.replace("email", "test@user.com")

      view
      |> form("#basic_user_sign_up_form", user: params)
      |> render_change()

      {:ok, lv, _html} = live(conn, ~p"/register")

      form =
        form(lv, "#basic_user_sign_up_form", user: params)

      conn = submit_form(form, conn)

      {:ok, _index_live, _html} = live(conn, ~p"/organisations")

      assert {:ok, user} = User.by_email("test@user.com")
      assert user.first_name == "Mary"
    end
  end
end
