defmodule Omedis.Accounts.ProjectTest do
  alias Omedis.Accounts.AccessRight
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Project

  describe "list_paginated/1" do
    setup do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()

      %{user: user, tenant: tenant}
    end

    test "returns projects only for users with read access", %{user: user, tenant: tenant} do
      {:ok, another_user} = create_user()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, another_group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})
      {:ok, _} = create_group_user(%{user_id: another_user.id, group_id: another_group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          create: true,
          read: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          create: true,
          read: false,
          tenant_id: tenant.id,
          group_id: another_group.id
        })

      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: user,
          tenant: tenant
        )

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert length(paginated_result.results) == 1
      assert hd(paginated_result.results).id == project.id

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: another_user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
    end

    test "returns empty list for users without read access", %{user: user, tenant: tenant} do
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          read: false,
          create: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, _} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: user,
          tenant: tenant
        )

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
    end

    test "returns an empty list for users without group membership", %{user: user, tenant: tenant} do
      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
    end

    test "returns an error if actor and tenant are not provided", %{user: user, tenant: tenant} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Project.list_paginated(page: [offset: 0, limit: 10, count: true])
    end
  end

  describe "create/1" do
    test "creates a project when user has create access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          create: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      attrs = %{name: "New Project", tenant_id: tenant.id, position: "1"}

      assert {:ok, project} = Project.create(attrs, actor: user, tenant: tenant)
      assert project.name == "New Project"
    end

    test "returns error when user doesn't have create access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          create: false,
          tenant_id: tenant.id,
          group_id: group.id
        })

      attrs = %{name: "New Project", tenant_id: tenant.id, position: "1"}

      assert {:error, %Ash.Error.Forbidden{}} = Project.create(attrs, actor: user, tenant: tenant)
    end
  end

  describe "update/1" do
    test "updates a project when user has write access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_access_right(%{
          resource_name: "Project",
          create: true,
          write: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: user,
          tenant: tenant
        )

      assert {:ok, updated_project} =
               Project.update(project, %{name: "Updated Project"}, actor: user, tenant: tenant)

      assert updated_project.name == "Updated Project"
    end

    test "returns error when user doesn't have update access" do
      {:ok, user} = create_user()
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

      {:ok, access_right} =
        create_access_right(%{
          resource_name: "Project",
          create: true,
          tenant_id: tenant.id,
          group_id: group.id
        })

      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"},
          actor: user,
          tenant: tenant
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               Project.update(project, %{name: "Updated Project"}, actor: user, tenant: tenant)
    end
  end
end
