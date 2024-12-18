defmodule Omedis.Groups.GroupTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Groups.Group

  setup do
    {:ok, user} = create_user()
    organisation = fetch_users_organisation(user.id)
    {:ok, authorized_user} = create_user()
    {:ok, group} = create_group(organisation)
    create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    create_access_right(organisation, %{
      group_id: group.id,
      read: true,
      resource_name: "Organisation",
      create: true,
      destroy: true,
      update: true
    })

    create_access_right(organisation, %{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      create: true,
      destroy: true,
      update: true
    })

    %{user: user, organisation: organisation, authorized_user: authorized_user}
  end

  describe "create/2" do
    test "organisation owner can create a group", %{user: user, organisation: organisation} do
      assert %Group{} =
               group =
               Group.create!(
                 %{
                   name: "Test Group",
                   user_id: user.id,
                   slug: "test-group"
                 },
                 actor: user,
                 tenant: organisation
               )

      assert group.user_id == user.id
      assert group.organisation_id == organisation.id
    end

    test "authorised users can create a group", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      assert %Group{} =
               group =
               Group.create!(
                 %{
                   name: "Test Group",
                   user_id: authorized_user.id,
                   slug: "test-group"
                 },
                 actor: authorized_user,
                 tenant: organisation
               )

      assert group.user_id == authorized_user.id
      assert group.organisation_id == organisation.id
    end

    test "unauthorised users cannot create a group" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()

      assert_raise Ash.Error.Forbidden, fn ->
        Group.create!(
          %{name: "Test Group", user_id: user.id},
          actor: user,
          tenant: organisation
        )
      end
    end
  end

  describe "update/2" do
    test "can update a group if user is the owner of the organisation", %{
      user: user,
      organisation: organisation
    } do
      {:ok, group} = create_group(organisation, %{user_id: user.id})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        update: true
      })

      assert %Group{} =
               updated_group =
               Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: organisation)

      assert updated_group.name == "Updated Group"
    end

    test "authorised users can update a group", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{user_id: authorized_user.id})

      assert %Group{} =
               updated_group =
               Group.update!(group, %{name: "New Name"},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert updated_group.name == "New Name"
    end

    test "unauthorized users cannot update group", %{
      user: user
    } do
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation, %{user_id: user.id})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        update: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.update!(group, %{name: "Updated Group"}, actor: user, tenant: organisation)
      end
    end
  end

  describe "destroy/2" do
    test "organisation owner can delete a group", %{user: user, organisation: organisation} do
      {:ok, group} = create_group(organisation, %{user_id: user.id})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        destroy: true
      })

      assert :ok =
               Group.destroy(group, actor: user, tenant: organisation)
    end

    test "authorized users can delete a group", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{user_id: authorized_user.id})

      assert :ok =
               Group.destroy(group, actor: authorized_user, tenant: organisation)
    end

    test "can't delete a group if actor doesn't have destroy access", %{
      user: user
    } do
      {:ok, organisation} = create_organisation()

      {:ok, group} =
        create_group(organisation, %{user_id: user.id, slug: "test-group"})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        destroy: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        Group.destroy!(group, actor: user, tenant: organisation)
      end
    end
  end

  describe "by_id!/1" do
    test "returns a group given a valid id", %{
      user: user,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{user_id: user.id, slug: "test-group"})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: true
      })

      assert %Group{} = result = Group.by_id!(group.id, actor: user, tenant: organisation)
      assert result.id == group.id
    end

    test "returns an error when an invalid group id is given", %{
      user: user,
      organisation: organisation
    } do
      invalid_id = Ecto.UUID.generate()

      create_group_membership(organisation, %{user_id: user.id, group_id: invalid_id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: invalid_id,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(invalid_id, actor: user, tenant: organisation)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user} do
      {:ok, organisation} = create_organisation()

      {:ok, group} =
        create_group(organisation, %{user_id: user.id, slug: "test-group"})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_id!(group.id, actor: user, tenant: organisation)
      end
    end
  end

  describe "by_organisation_id/1" do
    test "returns paginated groups the user and organisation have access to", %{
      user: user,
      organisation: organisation
    } do
      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(organisation, %{
            user_id: user.id,
            slug: "test-group-#{i}"
          })

        create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

        create_access_right(organisation, %{
          resource_name: "Group",
          group_id: group.id,
          read: true
        })
      end)

      assert %Ash.Page.Offset{results: groups} =
               Group.by_organisation_id!(%{organisation_id: organisation.id},
                 actor: user,
                 tenant: organisation,
                 page: [limit: 10, offset: 0]
               )

      assert length(groups) == 10
    end

    test "returns an empty list when actor doesn't have read access", %{
      user: user
    } do
      {:ok, organisation} = create_organisation()

      Enum.each(1..15, fn i ->
        {:ok, group} =
          create_group(organisation, %{
            user_id: user.id,
            slug: "test-group-#{i}"
          })

        create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

        create_access_right(organisation, %{
          resource_name: "Group",
          group_id: group.id,
          read: false
        })
      end)

      assert %Ash.Page.Offset{results: []} =
               Group.by_organisation_id!(%{organisation_id: organisation.id},
                 actor: user,
                 tenant: organisation
               )
    end
  end

  describe "latest_by_organisation_id/1" do
    test "returns the latest group for an organisation", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, group_1} =
        create_group(organisation, %{name: "Group 01"})

      past_datetime = DateTime.add(DateTime.utc_now(), -1, :second)

      {:ok, _updated_group_1} =
        Group.update(
          group_1,
          %{},
          context: %{updated_at: past_datetime},
          actor: authorized_user,
          tenant: organisation
        )

      {:ok, group_2} =
        create_group(organisation, %{name: "Group 02"})

      assert {:ok, [latest_group]} =
               Group.latest_by_organisation_id(
                 %{organisation_id: organisation.id},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert latest_group.id == group_2.id
      assert latest_group.name == "Group 02"
    end
  end

  describe "by_slug!/1" do
    test "returns a group given a valid slug and actor has read access", %{
      user: user,
      organisation: organisation
    } do
      {:ok, group} = create_group(organisation, %{user_id: user.id, slug: "test-group-slug"})
      {:ok, group2} = create_group(organisation, %{user_id: user.id})

      create_group_membership(organisation, %{user_id: user.id, group_id: group2.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: true
      })

      assert %Group{} =
               result = Group.by_slug!("test-group-slug", actor: user, tenant: organisation)

      assert result.id == group.id
    end

    test "returns an error when an invalid slug is given", %{
      user: user,
      organisation: organisation
    } do
      invalid_slug = "invalid-slug"

      create_group_membership(organisation, %{user_id: user.id, group_id: invalid_slug})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: invalid_slug,
        read: true
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(invalid_slug, actor: user, tenant: organisation)
      end
    end

    test "returns an error if actor doesn't have read access", %{user: user} do
      {:ok, organisation} = create_organisation()

      {:ok, group} = create_group(organisation, %{user_id: user.id, slug: "test-group-slug"})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: false
      })

      assert_raise Ash.Error.Query.NotFound, fn ->
        Group.by_slug!(group.slug, actor: user, tenant: organisation)
      end
    end
  end
end
