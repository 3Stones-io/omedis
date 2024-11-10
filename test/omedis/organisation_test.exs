defmodule Omedis.OrganisationTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Organisation

  setup do
    {:ok, user} = create_user()
    {:ok, organisation} = create_organisation()
    {:ok, group} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{group_id: group.id, user_id: user.id})

    {:ok, user: user, organisation: organisation, group: group}
  end

  describe "read/0" do
    test "returns organisations the user has read access to or is owner", %{
      user: user,
      organisation: organisation,
      group: group
    } do
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation"
      })

      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      {:ok, organisations} = Organisation.read(actor: user)
      assert length(organisations) == 2
      assert Enum.any?(organisations, fn t -> t.id == organisation.id end)
      assert Enum.any?(organisations, fn t -> t.id == owned_organisation.id end)
    end

    test "returns only owned organisations when user has no read access", %{user: user} do
      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      {:ok, organisations} = Organisation.read(actor: user)
      assert length(organisations) == 1
      assert hd(organisations).id == owned_organisation.id
    end
  end

  describe "create/1" do
    test "is only allowed for users without an organisation", %{user: user} do
      assert {:error, _} =
               Organisation.create(%{name: "New Organisation", slug: "new-organisation"},
                 actor: user
               )

      {:ok, user_without_organisation} = create_user()

      assert {:ok, _} =
               Organisation
               |> attrs_for(nil)
               |> Map.merge(%{
                 name: "New Organisation",
                 owner_id: user_without_organisation.id,
                 slug: "new-organisation"
               })
               |> Organisation.create(actor: user_without_organisation)
    end

    test "returns an error when attributes are invalid", %{user: user} do
      assert {:error, _} = Organisation.create(%{name: "Invalid Organisation"}, actor: user)
    end
  end

  describe "update/2" do
    test "requires write or update access", %{user: user, group: group} do
      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      assert {:ok, updated_organisation} =
               Organisation.update(owned_organisation, %{name: "Updated"}, actor: user)

      assert updated_organisation.name == "Updated"

      {:ok, organisation} = create_organisation()

      create_access_right(organisation, %{
        create: true,
        group_id: group.id,
        resource_name: "Organisation",
        read: true,
        update: false,
        write: false
      })

      assert {:error, _} = Organisation.update(organisation, %{name: "Updated"}, actor: user)

      create_access_right(organisation, %{
        group_id: group.id,
        resource_name: "Organisation",
        update: false,
        write: true
      })

      assert {:ok, updated_organisation} =
               Organisation.update(organisation, %{name: "Updated"}, actor: user)

      assert updated_organisation.name == "Updated"

      {:ok, organisation} = create_organisation()

      create_access_right(organisation, %{
        group_id: group.id,
        resource_name: "Organisation",
        update: true,
        write: false
      })

      assert {:ok, updated_organisation} =
               Organisation.update(organisation, %{name: "Updated"}, actor: user)

      assert updated_organisation.name == "Updated"
    end
  end

  describe "destroy/1" do
    test "requires ownership or write/update access", %{user: user, group: group} do
      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      assert :ok = Organisation.destroy(owned_organisation, actor: user)

      {:ok, organisation} = create_organisation()

      create_access_right(organisation, %{
        create: true,
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        update: false,
        write: false
      })

      assert {:error, _} = Organisation.destroy(organisation, actor: user)

      create_access_right(organisation, %{
        group_id: group.id,
        resource_name: "Organisation",
        update: false,
        write: true
      })

      assert :ok = Organisation.destroy(organisation, actor: user)

      {:ok, organisation} = create_organisation()

      create_access_right(organisation, %{
        group_id: group.id,
        resource_name: "Organisation",
        update: true,
        write: false
      })

      assert :ok = Organisation.destroy(organisation, actor: user)
    end
  end

  describe "by_id/1" do
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

      assert {:ok, fetched_organisation} = Organisation.by_id(organisation.id, actor: user)
      assert organisation.id == fetched_organisation.id
    end

    test "returns an error when user has no access", %{user: user, organisation: organisation} do
      assert {:error, _} = Organisation.by_id(organisation.id, actor: user)
    end

    test "returns an organisation for the owner without access rights", %{user: user} do
      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      assert {:ok, fetched_organisation} = Organisation.by_id(owned_organisation.id, actor: user)
      assert owned_organisation.id == fetched_organisation.id
    end
  end

  describe "by_slug/1" do
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

      assert {:ok, fetched_organisation} = Organisation.by_slug(organisation.slug, actor: user)
      assert organisation.slug == fetched_organisation.slug
    end

    test "returns an error when user has no access", %{user: user, organisation: organisation} do
      assert {:error, _} = Organisation.by_slug(organisation.slug, actor: user)
    end

    test "returns an organisation for the owner without access rights", %{user: user} do
      {:ok, owned_organisation} = create_organisation(%{owner_id: user.id})

      assert {:ok, fetched_organisation} =
               Organisation.by_slug(owned_organisation.slug, actor: user)

      assert owned_organisation.slug == fetched_organisation.slug
    end
  end

  describe "by_owner_id/1" do
    test "returns an organisation for a specific user", %{user: user} do
      {:ok, organisation} = create_organisation(%{slug: "organisation-one", owner_id: user.id})

      assert {:ok, [fetched_organisation]} =
               Organisation.by_owner_id(%{owner_id: user.id}, actor: user)

      assert organisation.id == fetched_organisation.id
    end

    test "returns an empty list when user owns no organisations", %{user: user} do
      assert {:ok, []} = Organisation.by_owner_id(%{owner_id: user.id}, actor: user)
    end
  end

  describe "list_paginated/1" do
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
               Organisation.list_paginated(actor: user, page: [limit: 10, offset: 0])

      assert length(organisations) == 10
      assert total_count == 15

      assert {:ok, %{results: next_page}} =
               Organisation.list_paginated(actor: user, page: [limit: 10, offset: 10])

      assert length(next_page) == 5
    end
  end
end
