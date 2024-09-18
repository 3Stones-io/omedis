defmodule Omedis.Factory do
  @moduledoc """
  Factory module for creating test data.
  """
  use ExMachina.Ecto, repo: Omedis.Repo
  alias Omedis.Accounts.User

  def insert_user(attrs \\ %{}) do
    user = %{
      first_name: "Test",
      last_name: "User",
      gender: "Male",
      birthdate: "1990-01-01",
      hashed_password: Bcrypt.hash_pwd_salt("password")
    }

    Map.merge(user, attrs)
    |> User.create()
  end

  def user_factory(attrs) do
    user = %User{
      first_name: "Test",
      last_name: "User",
      gender: "Male",
      birthdate: "1990-01-01",
      hashed_password: Bcrypt.hash_pwd_salt("password")
    }

    merge_attributes(user, attrs)
  end
end
