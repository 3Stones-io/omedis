defmodule Omedis.Fixtures do
  @moduledoc """
  This module contains functions to create fixtures for testing.
  """
  alias Omedis.Accounts

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        first_name: "Test",
        last_name: "User",
        email: "test#{System.unique_integer([:positive])}@example.com",
        gender: "Male",
        birthdate: "1990-01-01",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        lang: "en"
      })
      |> Accounts.User.create()

    user
  end

  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(%{
        name: "Test Tenant",
        street: "Wall Street",
        zip_code: "12345",
        city: "New York",
        country: "USA",
        slug: "test-tenant-#{System.unique_integer([:positive])}",
        timezone: "GMT+0200 (Europe/Berlin)"
      })
      |> Accounts.Tenant.create()

    tenant
  end
end
