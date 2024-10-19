defmodule Omedis.Accounts.ProjectTest do
  use Omedis.DataCase, async: true

  describe "list_paginated/1" do
    import Omedis.Fixtures

    alias Omedis.Accounts.Project

    test "returns paginated list of projects for a user with access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      for i <- 1..15 do
        {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project #{i}", position: "#{i}"})
      end

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 10, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert length(paginated_result.results) == 5
      assert paginated_result.count == 15
    end

    test "returns an empty list for a user without access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      # Create access right with read set to false
      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: false,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X", position: "1"})

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
    end

    test "returns projects only for the specified tenant" do
      {:ok, user} = create_user()
      {:ok, tenant_1} = create_tenant()
      {:ok, tenant_2} = create_tenant()
      {:ok, group_1} = create_group(%{tenant_id: tenant_1.id})
      {:ok, group_2} = create_group(%{tenant_id: tenant_2.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant_1.id,
          group_id: group_1.id
        })

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant_2.id,
          group_id: group_2.id
        })

      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group_1.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group_2.id})

      for i <- 1..5 do
        {:ok, _} =
          create_project(%{tenant_id: tenant_1.id, name: "T1 Project #{i}", position: "#{i}"})
      end

      for i <- 1..3 do
        {:ok, _} =
          create_project(%{tenant_id: tenant_2.id, name: "T2 Project #{i}", position: "#{i}"})
      end

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: tenant_1
               )

      assert length(paginated_result.results) == 5
      assert paginated_result.count == 5
      assert Enum.all?(paginated_result.results, &(&1.tenant_id == tenant_1.id))

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: tenant_2
               )

      assert length(paginated_result.results) == 3
      assert paginated_result.count == 3
      assert Enum.all?(paginated_result.results, &(&1.tenant_id == tenant_2.id))
    end

    test "returns an error if the actor is not provided" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X", position: "1"})

      assert {:error, %Ash.Error.Forbidden{} = _error} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 tenant: tenant
               )
    end

    test "returns an error if the tenant is not provided" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X", position: "1"})

      assert {:error, %Ash.Error.Forbidden{} = _error} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user
               )
    end

    test "returns empty list for user without group membership" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X", position: "1"})

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
    end
  end
end
