defmodule OmedisWeb.RegisterTest do
  use OmedisWeb.ConnCase
  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.User

  import Phoenix.LiveViewTest

  @valid_registration_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "test@gmail.com",
    "password" => "12345678",
    "gender" => "Male",
    "birthdate" => "1990-01-01",
    "lang" => "en",
    "daily_start_at" => "09:00:00",
    "daily_end_at" => "17:00:00"
  }

  @valid_tenant_params %{
    name: "Test Tenant",
    street: "123 Test St",
    zip_code: "12345",
    city: "Test City",
    country: "Test Country",
    slug: "test-tenant"
  }

  setup do
    {:ok, tenant} =
      Ash.Changeset.new(Tenant)
      |> Ash.Changeset.for_create(:create, @valid_tenant_params)
      |> Ash.create()

    {:ok, %{tenant: tenant}}
  end

  describe "Tests the Registration flow" do
    test "The registration form is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      assert has_element?(view, "#basic_user_sign_up_form")
    end

    test "Form fields are disabled until a tenant is selected", %{conn: conn, tenant: tenant} do
      {:ok, view, _html} = live(conn, "/register")

      assert view |> element("#user_email") |> render() =~ "disabled"

      view
      |> element("#select_tenant")
      |> render_change(tenant: %{id: tenant.id})

      refute view |> element("#user_email") |> render() =~ "disabled"
    end

    test "Once we make changes to the registration form, we see any errors if they are there", %{
      conn: conn,
      tenant: tenant
    } do
      {:ok, view, _html} = live(conn, "/register")

      view
      |> element("#select_tenant")
      |> render_change(tenant: %{id: tenant.id})

      html =
        view
        |> form("#basic_user_sign_up_form", user: %{"password" => "1"})
        |> render_change()

      assert html =~ "length must be greater than or equal to 8"
    end

    test "You can sign in with valid data", %{conn: conn} do
    test "You can sign in with valid data", %{conn: conn, tenant: tenant} do
      {:ok, view, _html} = live(conn, "/register")

      {:error, _} = User.by_email(@valid_registration_params["email"])

      view
      |> element("#select_tenant")
      |> render_change(tenant: %{id: tenant.id})

      view
      |> form("#basic_user_sign_up_form", user: @valid_registration_params)
      |> render_change()

      html =
        view
        |> form("#basic_user_sign_up_form", user: @valid_registration_params)
        |> render_submit()

      refute html =~ "Register"

      {:ok, user} = User.by_email(@valid_registration_params["email"])

      assert user.first_name == @valid_registration_params["first_name"]
    end
  end
end
