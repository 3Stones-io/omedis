defmodule Omedis.Accounts.ProjectTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Project

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, authorized_user} = create_user()
    {:ok, user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Project",
        tenant_id: tenant.id,
        write: true
      })

    %{authorized_user: authorized_user, group: group, owner: owner, tenant: tenant, user: user}
  end

  describe "list_paginated/1" do
    test "returns projects if user is the tenant owner" do
      {:ok, owner} = create_user()
      {:ok, another_user} = create_user()
      {:ok, tenant} = create_tenant(%{owner_id: owner.id})
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      {:ok, _} = create_group_user(%{group_id: group.id, user_id: another_user.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group.id,
          read: true,
          resource_name: "Project",
          tenant_id: tenant.id,
          write: true
        })

      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project"})

      assert {:ok, %{results: projects}} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: owner,
                 tenant: tenant
               )

      assert length(projects) == 1
      assert hd(projects).id == project.id
    end

    test "returns paginated list of projects the user has access to" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, other_tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, other_group} = create_group(%{tenant_id: other_tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: other_group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      # Create another access right with read set to false
      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: false,
          tenant_id: other_tenant.id,
          group_id: other_group.id
        })

      for i <- 1..10 do
        {:ok, _} =
          create_project(%{
            tenant_id: tenant.id,
            name: "Accessible Project #{i}",
            position: "#{i}"
          })
      end

      for i <- 1..10 do
        {:ok, _} =
          create_project(%{
            tenant_id: other_tenant.id,
            name: "Inaccessible Project #{i}",
            position: "#{i}"
          })
      end

      # Return projects the user has access to
      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 20, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert length(paginated_result.results) == 10
      assert paginated_result.count == 10
      assert Enum.all?(paginated_result.results, &(&1.tenant_id == tenant.id))

      assert Enum.all?(
               paginated_result.results,
               &String.starts_with?(&1.name, "Accessible Project")
             )

      # Return an empty list if the user doesn't have access
      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 20, count: true],
                 actor: user,
                 tenant: other_tenant
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
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
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X"})

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
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X"})

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
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X"})

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

      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Project X"})

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

  describe "create/1" do
    test "tenant owner can create a project", %{owner: owner, tenant: tenant} do
      attrs = %{name: "New Project", tenant_id: tenant.id, position: "1"}

      assert {:ok, project} = Project.create(attrs, actor: owner, tenant: tenant)
      assert project.name == "New Project"
    end

    test "authorized user can create a project", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      attrs = %{name: "New Project", tenant_id: tenant.id, position: "1"}

      assert {:ok, project} = Project.create(attrs, actor: authorized_user, tenant: tenant)
      assert project.name == "New Project"
    end

    test "unauthorized user cannot create a project", %{user: user, tenant: tenant} do
      attrs = %{name: "New Project", tenant_id: tenant.id, position: "1"}

      assert {:error, %Ash.Error.Forbidden{}} = Project.create(attrs, actor: user, tenant: tenant)
    end
  end

  describe "update/1" do
    test "tenant owner can update a project", %{owner: owner, tenant: tenant} do
      {:ok, project} =
        Project.create(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: owner,
          tenant: tenant
        )

      assert {:ok, updated_project} =
               Project.update(project, %{name: "Updated Project"}, actor: owner, tenant: tenant)

      assert updated_project.name == "Updated Project"
    end

    test "authorized user can update a project", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      {:ok, project} =
        Project.create(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: authorized_user,
          tenant: tenant
        )

      assert {:ok, updated_project} =
               Project.update(project, %{name: "Updated Project"},
                 actor: authorized_user,
                 tenant: tenant
               )

      assert updated_project.name == "Updated Project"
    end

    test "unauthorized user cannot update a project", %{
      authorized_user: authorized_user,
      user: user,
      tenant: tenant
    } do
      {:ok, project} =
        Project.create(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: authorized_user,
          tenant: tenant
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               Project.update(project, %{name: "Updated Project"}, actor: user, tenant: tenant)
    end
  end
end
