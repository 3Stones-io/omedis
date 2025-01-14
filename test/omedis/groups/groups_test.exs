defmodule Omedis.Groups.GroupsTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Groups
  alias Omedis.Groups.Group

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, group} = create_group(organisation)
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        create: true,
        destroy: true,
        update: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "GroupMembership",
        destroy: true,
        create: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Group",
        create: true,
        destroy: true,
        update: true
      })

    %{
      user: user,
      owner: owner,
      organisation: organisation,
      authorized_user: authorized_user,
      group: group
    }
  end

  describe "create_group/2" do
    test "organisation owner can create a group", %{owner: owner, organisation: organisation} do
      assert %Group{} =
               group =
               Groups.create_group!(
                 %{
                   name: "Test Group",
                   user_id: owner.id,
                   slug: "test-group"
                 },
                 actor: owner,
                 tenant: organisation
               )

      assert group.user_id == owner.id
      assert group.organisation_id == organisation.id
    end

    test "authorised users can create a group", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      assert %Group{} =
               group =
               Groups.create_group!(
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
        Groups.create_group!(
          %{name: "Test Group", user_id: user.id},
          actor: user,
          tenant: organisation
        )
      end
    end
  end

  describe "update_group/2" do
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
               Groups.update_group!(group, %{name: "Updated Group"},
                 actor: user,
                 tenant: organisation
               )

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
               Groups.update_group!(group, %{name: "New Name"},
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
        Groups.update_group!(group, %{name: "Updated Group"}, actor: user, tenant: organisation)
      end
    end
  end

  describe "destroy_group/2" do
    test "organisation owner can delete a group", %{user: user, organisation: organisation} do
      {:ok, group} = create_group(organisation, %{user_id: user.id})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        destroy: true
      })

      assert :ok =
               Groups.destroy_group(group, actor: user, tenant: organisation)
    end

    test "authorized users can delete a group", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, group} =
        create_group(organisation, %{user_id: authorized_user.id})

      assert :ok =
               Groups.destroy_group(group, actor: authorized_user, tenant: organisation)
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
        Groups.destroy_group!(group, actor: user, tenant: organisation)
      end
    end
  end

  describe "get_group_by_id!/1" do
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

      assert %Group{} =
               result = Groups.get_group_by_id!(group.id, actor: user, tenant: organisation)

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
        Groups.get_group_by_id!(invalid_id, actor: user, tenant: organisation)
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
        Groups.get_group_by_id!(group.id, actor: user, tenant: organisation)
      end
    end
  end

  describe "get_group_by_organisation_id/1" do
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
               Groups.get_group_by_organisation_id!(%{organisation_id: organisation.id},
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
               Groups.get_group_by_organisation_id!(%{organisation_id: organisation.id},
                 actor: user,
                 tenant: organisation
               )
    end
  end

  describe "latest_group_by_organisation_id/1" do
    test "returns the latest group for an organisation", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      {:ok, group_1} =
        create_group(organisation, %{name: "Group 01"})

      past_datetime = DateTime.add(DateTime.utc_now(), -1, :second)

      {:ok, _updated_group_1} =
        Groups.update_group(
          group_1,
          %{},
          context: %{updated_at: past_datetime},
          actor: authorized_user,
          tenant: organisation
        )

      {:ok, group_2} =
        create_group(organisation, %{name: "Group 02"})

      assert {:ok, [latest_group]} =
               Groups.latest_group_by_organisation_id(
                 %{organisation_id: organisation.id},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert latest_group.id == group_2.id
      assert latest_group.name == "Group 02"
    end
  end

  describe "get_group_by_slug!/1" do
    test "returns a group given a valid slug and actor has read access", %{
      user: user,
      organisation: organisation
    } do
      {:ok, group} = create_group(organisation, %{user_id: user.id, slug: "test-group-slug"})

      create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      create_access_right(organisation, %{
        resource_name: "Group",
        group_id: group.id,
        read: true
      })

      assert %Group{} =
               result =
               Groups.get_group_by_slug!("test-group-slug", actor: user, tenant: organisation)

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
        Groups.get_group_by_slug!(invalid_slug, actor: user, tenant: organisation)
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
        Groups.get_group_by_slug!(group.slug, actor: user, tenant: organisation)
      end
    end
  end

  describe "create_group_membership/1" do
    test "organisation owner can create a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_membership} =
               Groups.create_group_membership(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: owner,
                 tenant: organisation
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "authorized user can create a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      assert {:ok, group_membership} =
               Groups.create_group_membership(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: authorized_user,
                 tenant: organisation
               )

      assert group_membership.group_id == group.id
      assert group_membership.user_id == user.id
    end

    test "unauthorized user cannot create a group_membership", %{
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               Groups.create_group_membership(
                 %{
                   group_id: group.id,
                   user_id: user.id
                 },
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end

  describe "get_group_memberships/0" do
    test "organisation owner can read all group_memberships", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, group_memberships} = Groups.get_group_memberships(actor: owner, tenant: organisation)
      assert length(group_memberships) > 0
    end

    test "authorized user can read all group_memberships", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      {:ok, group_memberships} =
        Groups.get_group_memberships(actor: authorized_user, tenant: organisation)

      assert length(group_memberships) > 0
    end

    test "unauthorized user cannot read group_memberships", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, _group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()

      assert {:ok, []} =
               Groups.get_group_memberships(actor: unauthorized_user, tenant: organisation)
    end
  end

  describe "destroy_group_membership/1" do
    test "organisation owner can delete a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      assert :ok =
               Groups.destroy_group_membership(group_membership,
                 actor: owner,
                 tenant: organisation
               )

      {:ok, group_memberships} = Groups.get_group_memberships(actor: owner, tenant: organisation)
      refute Enum.any?(group_memberships, fn gm -> gm.id == group_membership.id end)
    end

    test "authorized user can delete a group_membership", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: authorized_user,
          tenant: organisation
        )

      assert :ok =
               Groups.destroy_group_membership(group_membership,
                 actor: authorized_user,
                 tenant: organisation
               )

      {:ok, group_memberships} =
        Groups.get_group_memberships(actor: authorized_user, tenant: organisation)

      refute Enum.any?(group_memberships, fn gm -> gm.user_id == group_membership.user_id end)
    end

    test "unauthorized user cannot delete a group_membership", %{
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    } do
      {:ok, group_membership} =
        Groups.create_group_membership(
          %{
            group_id: group.id,
            user_id: user.id
          },
          actor: owner,
          tenant: organisation
        )

      {:ok, unauthorized_user} = create_user()

      assert {:error, _} =
               Groups.destroy_group_membership(group_membership,
                 actor: unauthorized_user,
                 tenant: organisation
               )
    end
  end
end
