defmodule Omedis.AccountsTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Accounts
  alias Omedis.Invitations

  require Ash.Query

  @admin_full_access_resources [
    "AccessRight",
    "Activity",
    "Event",
    "Group",
    "GroupMembership",
    "Event",
    "Invitation",
    "InvitationGroup",
    "Organisation",
    "Project",
    "Token"
  ]

  @admin_read_only_resources ["User"]

  @user_read_only_resources [
    "AccessRight",
    "Activity",
    "Group",
    "GroupMembership",
    "Invitation",
    "InvitationGroup",
    "Organisation",
    "Project",
    "Token",
    "User"
  ]

  @user_create_resources ["Event"]

  defp organisation_setup(_context) do
    {:ok, user} = create_user()
    organisation = fetch_users_organisation(user.id)
    {:ok, group} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

    %{user: user, organisation: organisation, group: group}
  end

  describe "slug_exists?/3" do
    setup [:organisation_setup]

    test "checks if a slug exists for a resource", %{organisation: organisation, user: owner} do
      assert Accounts.slug_exists?(Accounts.Organisation, [slug: organisation.slug], actor: owner)
    end

    test "returns false if a slug does not exist for a resource", %{user: owner} do
      refute Accounts.slug_exists?(Accounts.Organisation, [slug: "non-existent-slug"],
               actor: owner
             )
    end
  end

  # Organisation tests
  describe "create_organisation/2" do
    setup [:organisation_setup]

    require Ash.Query

    alias Omedis.AccessRights.AccessRight
    alias Omedis.Groups.Group
    alias Omedis.Groups.GroupMembership
    alias Omedis.Projects.Project
    alias Omedis.TimeTracking.Activity

    test "users can only have one organisation" do
      {:ok, user} = create_user()

      assert fetch_users_organisation(user.id)

      assert {:error, _} =
               Accounts.create_organisation(
                 %{
                   name: "New Organisation",
                   slug: "new-organisation",
                   owner_id: user.id
                 },
                 actor: user
               )
    end

    test "returns an error when attributes are invalid", %{user: user} do
      assert {:error, _} =
               Accounts.create_organisation(%{name: "Invalid Organisation"}, actor: user)
    end

    test "creates administrators group and adds organisation owner to it", %{
      user: user,
      organisation: organisation
    } do
      assert {:ok, [admins_group]} =
               Group
               |> Ash.Query.filter(slug: "administrators", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      assert {:ok, [group_membership]} =
               GroupMembership
               |> Ash.Query.filter(user_id: user.id, group_id: admins_group.id)
               |> Ash.read(actor: user, tenant: organisation)

      assert group_membership.user_id == user.id
      assert group_membership.group_id == admins_group.id
    end

    test "creates administrators group with full access rights to select resources", %{
      user: user,
      organisation: organisation
    } do
      assert {:ok, [admins_group]} =
               Group
               |> Ash.Query.filter(slug: "administrators", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      Enum.each(@admin_full_access_resources, fn resource_name ->
        assert {:ok, [access_right]} =
                 AccessRight
                 |> Ash.Query.filter(group_id: admins_group.id, resource_name: resource_name)
                 |> Ash.read(actor: user, tenant: organisation)

        assert access_right.create == true
        assert access_right.read == true
        assert access_right.update == true
        assert access_right.destroy == true
      end)

      # Special case for resources with read-only access
      Enum.each(@admin_read_only_resources, fn resource_name ->
        assert {:ok, [user_access_right]} =
                 AccessRight
                 |> Ash.Query.filter(group_id: admins_group.id, resource_name: resource_name)
                 |> Ash.read(actor: user, tenant: organisation)

        assert user_access_right.create == false
        assert user_access_right.read == true
        assert user_access_right.update == false
        assert user_access_right.destroy == false
      end)
    end

    test "creates users group with read-only access rights to select resources", %{
      user: user,
      organisation: organisation
    } do
      assert {:ok, [users_group]} =
               Group
               |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      Enum.each(@user_read_only_resources, fn resource_name ->
        assert {:ok, [access_right]} =
                 AccessRight
                 |> Ash.Query.filter(group_id: users_group.id, resource_name: resource_name)
                 |> Ash.read(actor: user, tenant: organisation)

        assert access_right.create == false
        assert access_right.read == true
        assert access_right.update == false
        assert access_right.destroy == false
      end)
    end

    test "creates users group with create-only create access to select resources", %{
      user: user,
      organisation: organisation
    } do
      assert {:ok, [users_group]} =
               Group
               |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      Enum.each(@user_create_resources, fn resource_name ->
        assert {:ok, [users_group_rights]} =
                 AccessRight
                 |> Ash.Query.filter(group_id: users_group.id, resource_name: resource_name)
                 |> Ash.read(actor: user, tenant: organisation)

        assert users_group_rights.create == true
        assert users_group_rights.read == true
        assert users_group_rights.update == false
        assert users_group_rights.destroy == false
      end)
    end

    test "creates a default project", %{user: user, organisation: organisation} do
      assert {:ok, [project]} =
               Omedis.Projects.Project
               |> Ash.Query.filter(organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      assert project.name == "Project 1"
      assert project.position == "1"
    end

    test "creates a default activity", %{user: user, organisation: organisation} do
      assert {:ok, [users_group]} =
               Group
               |> Ash.Query.filter(slug: "users", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      assert {:ok, [project]} =
               Project
               |> Ash.Query.filter(name: "Project 1", organisation_id: organisation.id)
               |> Ash.read(actor: user, tenant: organisation)

      assert {:ok, [activity]} =
               Activity
               |> Ash.Query.filter(
                 group_id: users_group.id,
                 project_id: project.id,
                 slug: "miscellaneous"
               )
               |> Ash.read(actor: user, tenant: organisation)

      assert activity.name == "Miscellaneous"
    end
  end

  describe "update_organisation/2" do
    setup [:organisation_setup]

    test "requires update access", %{user: user, group: group, organisation: owned_organisation} do
      assert {:ok, updated_organisation} =
               Accounts.update_organisation(owned_organisation, %{name: "Updated"}, actor: user)

      assert updated_organisation.name == "Updated"

      {:ok, organisation} = create_organisation()

      create_access_right(organisation, %{
        create: true,
        group_id: group.id,
        resource_name: "Organisation",
        read: true,
        update: false
      })

      assert {:error, _} =
               Accounts.update_organisation(organisation, %{name: "Updated"}, actor: user)

      create_access_right(organisation, %{
        group_id: group.id,
        resource_name: "Organisation",
        update: true
      })

      assert {:ok, updated_organisation} =
               Accounts.update_organisation(organisation, %{name: "Updated"}, actor: user)

      assert updated_organisation.name == "Updated"
    end
  end

  describe "get_organisation_by_id/2" do
    setup [:organisation_setup]

    test "returns an organisation given a valid id", %{
      user: user,
      organisation: organisation,
      group: group
    } do
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

      assert {:ok, fetched_organisation} =
               Accounts.get_organisation_by_id(organisation.id, actor: user)

      assert organisation.id == fetched_organisation.id
    end

    test "returns an error when user has no access", %{organisation: organisation} do
      {:ok, user_2} = create_user()

      assert {:error, _} = Accounts.get_organisation_by_id(organisation.id, actor: user_2)
    end

    test "returns an organisation for the owner without access rights", %{
      user: user,
      organisation: owned_organisation
    } do
      assert {:ok, fetched_organisation} =
               Accounts.get_organisation_by_id(owned_organisation.id, actor: user)

      assert owned_organisation.id == fetched_organisation.id
    end
  end

  describe "get_organisation_by_slug/2" do
    setup [:organisation_setup]

    test "returns an organisation given a slug", %{
      user: user,
      organisation: organisation,
      group: group
    } do
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

      assert {:ok, fetched_organisation} =
               Accounts.get_organisation_by_slug(organisation.slug, actor: user)

      assert organisation.slug == fetched_organisation.slug
    end

    test "returns an error when user has no access", %{organisation: organisation} do
      {:ok, user_2} = create_user()

      assert {:error, _} = Accounts.get_organisation_by_slug(organisation.slug, actor: user_2)
    end

    test "returns an organisation for the owner without access rights", %{
      user: user,
      organisation: owned_organisation
    } do
      assert {:ok, fetched_organisation} =
               Accounts.get_organisation_by_slug(owned_organisation.slug, actor: user)

      assert owned_organisation.slug == fetched_organisation.slug
    end
  end

  describe "list_paginated_organisations/2" do
    setup [:organisation_setup]

    test "returns paginated organisations the user has access to", %{user: user, group: group} do
      Enum.each(1..15, fn i ->
        {:ok, organisation} =
          create_organisation(%{name: "Organisation #{i}", slug: "organisation-#{i}"})

        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Organisation"
        })
      end)

      assert {:ok, %{results: organisations, count: total_count}} =
               Accounts.list_paginated_organisations(actor: user, page: [limit: 10, offset: 0])

      assert length(organisations) == 10
      # Also includes the owned organisation created when user creates an organisation
      assert total_count == 16

      assert {:ok, %{results: next_page}} =
               Accounts.list_paginated_organisations(actor: user, page: [limit: 10, offset: 10])

      assert length(next_page) == 6
    end
  end

  # User tests
  describe "create_user/1" do
    test "creates a user given valid attributes" do
      # a user is created with the valid attributes
      assert {:ok, _user} =
               Accounts.create_user(%{
                 email: "wintermeyer@gmail.com",
                 hashed_password: Bcrypt.hash_pwd_salt("password"),
                 first_name: "Stefan",
                 last_name: "Wintermeyer",
                 gender: "Male",
                 birthdate: "1980-01-01"
               })

      #  an error is returned when the attributes are invalid

      assert {:error, _} =
               Accounts.create_user(%{
                 last_name: "Wintermeyer",
                 first_name: "Stefan"
               })
    end

    test "updates the associated invitation when user is created" do
      {:ok, organisation} = create_organisation()
      {:ok, invitation} = create_invitation(organisation, %{email: "test@user.com"})

      assert {:ok, user} =
               Accounts.create_user(%{
                 email: "test@user.com",
                 hashed_password: Bcrypt.hash_pwd_salt("password"),
                 first_name: "Stefan",
                 last_name: "Wintermeyer",
                 gender: "Male",
                 birthdate: "1980-01-01"
               })

      {:ok, updated_invitation} = Invitations.get_invitation_by_id(invitation.id)

      assert updated_invitation.user_id == user.id
    end

    test "adds the invited user to the selected groups" do
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
        Accounts.User
        |> attrs_for(nil)
        |> Map.put(:current_organisation_id, organisation.id)
        |> Map.put(:email, "test@user.com")

      assert {:ok, user} = Accounts.create_user(params)

      assert {:ok, user_group_memberships} =
               Omedis.Groups.GroupMembership
               |> Ash.Query.filter(user_id: user.id)
               |> Ash.read(authorize?: false, tenant: organisation)

      assert length(user_group_memberships) == 2
      assert user.id in Enum.map(user_group_memberships, & &1.user_id)
      assert group_1.id in Enum.map(user_group_memberships, & &1.group_id)
      assert group_2.id in Enum.map(user_group_memberships, & &1.group_id)
    end

    test "does not add the user to the users group if the user is not an invitee" do
      {:ok, organisation_owner} = create_user()

      {:ok, organisation} =
        create_organisation(%{owner_id: organisation_owner.id}, actor: organisation_owner)

      assert {:ok, _user} =
               Accounts.create_user(%{
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
  end

  describe "update_user/2" do
    test "updates a user given valid attributes" do
      {:ok, user} =
        create_user(%{email: "test@gmail.com"})

      assert {:ok, user} =
               Accounts.update_user(user, %{
                 first_name: "Stefan"
               })

      assert user.first_name == "Stefan"
    end
  end

  describe "delete_user/2" do
    test "an organisation owner cannot delete their account if they are the only admin" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})

      {:ok, _user_2} = create_user(%{email: "test2@gmail.com"})

      {:ok, users} = Ash.read(Accounts.User)
      refute Enum.empty?(users)

      assert_raise Ash.Error.Forbidden, fn ->
        Accounts.delete_user!(user, actor: user)
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

      {:ok, users} = Ash.read(Accounts.User)
      refute Enum.empty?(users)

      assert :ok = Accounts.delete_user!(user, actor: user)

      assert_raise Ash.Error.Invalid, fn ->
        Ash.get!(Accounts.User, user.id)
      end

      {:ok, users} = Ash.read(Accounts.User)
      assert length(users) == 1
    end

    test "unauthorised users cannot delete accounts" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
      {:ok, user2} = create_user(%{email: "test2@gmail.com"})

      assert_raise Ash.Error.Forbidden, fn ->
        Accounts.delete_user!(user, actor: user2)
      end
    end
  end

  describe "get_user_by_id/1" do
    test "returns a user given a valid id" do
      {:ok, user} = create_user(%{email: "test@gmail.com"})
      {:ok, fetched_user} = Accounts.get_user_by_id(user.id)
      assert user.id == fetched_user.id
    end
  end

  describe "get_user_by_email/1" do
    test "returns a user given a valid email" do
      {:ok, user} =
        create_user(%{email: "test@gmail.com"})

      {:ok, fetched_user} = Accounts.get_user_by_email(user.email)

      assert user.id == fetched_user.id
    end
  end
end
