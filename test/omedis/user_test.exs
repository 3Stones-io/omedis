defmodule Omedis.FarmersTest do
  use Omedis.DataCase

  alias Omedis.Accounts.User
  alias Omedis.Factory

  describe "User Resource Unit Tests" do
    test "read/0  returns all users" do
      Factory.insert(:user, %{email: "test@gmail.com"})

      {:ok, users} = User.read()
      assert Enum.empty?(users) == false
    end

    test "create/1 creates a user given valid attributes" do
      # a user is created with the valid attributes
      assert {:ok, _user} =
               User.create(%{
                 email: "wintermeyer@gmail.com",
                 hashed_password: Bcrypt.hash_pwd_salt("password"),
                 first_name: "Stefan",
                 last_name: "Wintermeyer",
                 gender: "Male",
                 birthdate: "1980-01-01"
               })

      #  an error is returned when the attributes are invalid

      assert {:error, _} =
               User.create(%{
                 last_name: "Wintermeyer",
                 first_name: "Stefan"
               })
    end

    test "update/2 updates a user given valid attributes" do
      {:ok, user} =
        Factory.insert_user(%{email: "test@gmail.com"})

      assert {:ok, user} =
               User.update(user, %{
                 first_name: "Stefan"
               })

      assert user.first_name == "Stefan"
    end

    test "destroy/1 deletes a user" do
      {:ok, user} =
        Factory.insert_user(%{email: "test@gmail.com"})

      {:ok, users} = User.read()
      assert Enum.empty?(users) == false

      assert :ok = User.destroy(user)

      {:ok, users} = User.read()
      assert Enum.empty?(users) == true
    end

    test "by_id/1 returns a user given a valid id" do
      {:ok, user} =
        Factory.insert_user(%{email: "test@gmail.com"})

      {:ok, fetched_user} = User.by_id(user.id)

      assert user.id == fetched_user.id
    end

    test "by_email/1 returns a user given a valid email" do
      {:ok, user} =
        Factory.insert_user(%{email: "test@gmail.com"})

      {:ok, fetched_user} = User.by_email(user.email)

      assert user.id == fetched_user.id
    end
  end
end
