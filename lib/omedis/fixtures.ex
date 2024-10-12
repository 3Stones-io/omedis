defmodule Omedis.Fixtures do
  @moduledoc """
  Fixtures for the Omedis system.
  """

  alias Omedis.Accounts

  def create_group(attrs \\ %{}) do
    fixture(Accounts.Group, attrs)
  end

  def create_group_user(attrs \\ %{}) do
    fixture(Accounts.GroupUser, attrs)
  end

  def create_tenant(attrs \\ %{}) do
    fixture(Accounts.Tenant, attrs)
  end

  def create_user(attrs \\ %{}) do
    fixture(Accounts.User, attrs)
  end

  def attrs_for(Accounts.Group) do
    %{
      name: Faker.Company.name(),
      slug: Faker.Lorem.word()
    }
  end

  def attrs_for(Accounts.GroupUser) do
    %{
      group_id: fn -> create_group().id end,
      user_id: fn -> create_user().id end
    }
  end

  def attrs_for(Accounts.Tenant) do
    %{
      city: Faker.Address.city(),
      country: Faker.Address.country(),
      name: Faker.Company.name(),
      slug: Faker.Lorem.word() <> "-#{Faker.random_between(1000, 9999)}",
      street: Faker.Address.street_address(),
      zip_code: Faker.Address.zip_code()
    }
  end

  def attrs_for(Accounts.User) do
    %{
      birthdate: Faker.Date.between(~D[1950-01-01], ~D[2000-01-01]),
      email: Faker.Internet.email(),
      first_name: Faker.Person.first_name(),
      gender: Enum.random(["Male", "Female"]),
      hashed_password: Bcrypt.hash_pwd_salt("password"),
      last_name: Faker.Person.last_name()
    }
  end

  defp fixture(module, attrs) do
    attrs =
      module
      |> attrs_for()
      |> Map.merge(attrs)
      |> Enum.map(fn
        {key, value} when is_function(value, 0) -> {key, value.()}
        element -> element
      end)
      |> Map.new()

    Ash.create(module, attrs)
  end
end