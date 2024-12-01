defmodule Omedis.FarmersTest do
  use Omedis.DataCase

  alias Omedis.Accounts.User

  describe "User Resource Unit Tests" do
    test "read/0  returns all users" do
      create_user(%{email: "test@gmail.com"})

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
        create_user(%{email: "test@gmail.com"})

      assert {:ok, user} =
               User.update(user, %{
                 first_name: "Stefan"
               })

      assert user.first_name == "Stefan"
    end

    test "an organisation owner cannot delete their account if they are the only admin" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
      {:ok, organisation} = create_organisation(%{owner_id: user.id})

      {:ok, admin_group} =
        create_group(organisation, %{
          name: "Administrators",
          slug: "administrators",
          user_id: user.id
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "Group"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "GroupMembership"
        })

      {:ok, _} =
        create_group_membership(organisation, %{group_id: admin_group.id, user_id: user.id})

      {:ok, _user_2} = create_user(%{email: "test2@gmail.com"})

      {:ok, users} = User.read()
      assert Enum.empty?(users) == false

      assert_raise Ash.Error.Forbidden, fn ->
        User.destroy!(user, actor: user)
      end
    end

    test "an organisation owner can delete their account if they are not the only admin" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
      {:ok, user_2} = create_user(%{email: "test2@gmail.com"})
      {:ok, organisation} = create_organisation(%{owner_id: user.id})

      {:ok, admin_group} =
        create_group(organisation, %{
          name: "Administrators",
          slug: "administrators",
          user_id: user.id
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "Group"
        })

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: admin_group.id,
          read: true,
          resource_name: "GroupMembership"
        })

      {:ok, _} =
        create_group_membership(organisation, %{group_id: admin_group.id, user_id: user.id})

      {:ok, _} =
        create_group_membership(organisation, %{group_id: admin_group.id, user_id: user_2.id})

      {:ok, users} = User.read()
      assert Enum.empty?(users) == false

      assert :ok = User.destroy!(user, actor: user)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(User, user.id)
      end

      {:ok, users} = User.read()
      assert length(users) == 1
    end

    test "unauthorised users cannot delete accounts" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
      {:ok, _} = create_organisation(%{owner_id: user.id})
      {:ok, user2} = create_user(%{email: "test2@gmail.com"})

      assert_raise Ash.Error.Forbidden, fn ->
        User.destroy!(user, actor: user2)
      end
    end

    test "by_id/1 returns a user given a valid id" do
      {:ok, user} =
        create_user(%{email: "test@gmail.com"})

      {:ok, fetched_user} = User.by_id(user.id)

      assert user.id == fetched_user.id
    end

    test "by_email/1 returns a user given a valid email" do
      {:ok, user} =
        create_user(%{email: "test@gmail.com"})

      {:ok, fetched_user} = User.by_email(user.email)

      assert user.id == fetched_user.id
    end
  end
end
