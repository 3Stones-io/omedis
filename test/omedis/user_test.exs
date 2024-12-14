defmodule Omedis.FarmersTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Accounts.User
  alias Omedis.Invitations.Invitation

  require Ash.Query

  describe "User Resource Unit Tests" do
    test "read/0  returns all users" do
      create_user(%{email: "test@gmail.com"})

      {:ok, users} = User.read()
      refute Enum.empty?(users)
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

    test "create/1 updates the associated invitation when user is created" do
      {:ok, organisation} = create_organisation()
      {:ok, invitation} = create_invitation(organisation, %{email: "test@user.com"})

      assert {:ok, user} =
               User.create(%{
                 email: "test@user.com",
                 hashed_password: Bcrypt.hash_pwd_salt("password"),
                 first_name: "Stefan",
                 last_name: "Wintermeyer",
                 gender: "Male",
                 birthdate: "1980-01-01"
               })

      {:ok, updated_invitation} = Invitation.by_id(invitation.id)

      assert updated_invitation.user_id == user.id
    end

    test "create/1 adds the invited user to the selected groups" do
      {:ok, organisation} = create_organisation()
      {:ok, group_1} = create_group(organisation, %{name: "Group 1"})
      {:ok, group_2} = create_group(organisation, %{name: "Group 2"})

      {:ok, invitation} = create_invitation(organisation, %{email: "test@user.com"})

      {:ok, _} =
        create_invitation_group(organisation, %{
          group_id: group_1.id,
          invitation_id: invitation.id
        })

      {:ok, _} =
        create_invitation_group(organisation, %{
          group_id: group_2.id,
          invitation_id: invitation.id
        })

      params =
        User
        |> attrs_for(nil)
        |> Map.put(:current_organisation_id, organisation.id)
        |> Map.put(:email, "test@user.com")

      assert {:ok, user} = User.create(params)

      assert {:ok, user_group_memberships} =
               Omedis.Groups.GroupMembership
               |> Ash.Query.filter(user_id: user.id)
               |> Ash.read(authorize?: false, tenant: organisation)

      assert length(user_group_memberships) == 2
      assert user.id in Enum.map(user_group_memberships, & &1.user_id)
      assert group_1.id in Enum.map(user_group_memberships, & &1.group_id)
      assert group_2.id in Enum.map(user_group_memberships, & &1.group_id)
    end

    test "create/1 does not add the user to the users group if the user is not an invitee" do
      {:ok, organisation_owner} = create_user()

      {:ok, organisation} =
        create_organisation(%{owner_id: organisation_owner.id}, actor: organisation_owner)

      assert {:ok, _user} =
               User.create(%{
                 email: "test@user.com",
                 hashed_password: Bcrypt.hash_pwd_salt("password"),
                 first_name: "Stefan",
                 last_name: "Wintermeyer",
                 gender: "Male",
                 birthdate: "1980-01-01"
               })

      assert {:ok, [users_group]} =
               Omedis.Groups.Group
               |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
               |> Ash.read(authorize?: false, tenant: organisation, load: :group_memberships)

      assert [] = users_group.group_memberships
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

      {:ok, _user_2} = create_user(%{email: "test2@gmail.com"})

      {:ok, users} = User.read()
      refute Enum.empty?(users)

      assert_raise Ash.Error.Forbidden, fn ->
        User.destroy!(user, actor: user)
      end
    end

    test "an organisation owner can delete their account if they are not the only admin" do
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

      {:ok, users} = User.read()
      refute Enum.empty?(users)

      assert :ok = User.destroy!(user, actor: user)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(User, user.id)
      end

      {:ok, users} = User.read()
      assert length(users) == 1
    end

    test "unauthorised users cannot delete accounts" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
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
