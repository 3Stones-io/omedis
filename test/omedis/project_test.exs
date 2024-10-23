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
    test "returns projects if user is the tenant owner", %{owner: owner, tenant: tenant} do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      assert {:ok, %{results: projects}} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: owner,
                 tenant: tenant
               )

      assert length(projects) == 1
      assert hd(projects).id == project.id
    end

    test "returns projects only for authorized users", %{
      authorized_user: authorized_user,
      tenant: tenant,
      user: unauthorized_user
    } do
      {:ok, project} =
        create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      assert {:ok, %{results: projects}} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: authorized_user,
                 tenant: tenant
               )

      assert length(projects) == 1
      assert hd(projects).id == project.id

      # Unauthorized user
      assert {:ok, %{results: projects}} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: unauthorized_user,
                 tenant: tenant
               )

      assert Enum.empty?(projects)
    end

    test "returns empty list for unauthorized users", %{user: user, tenant: tenant} do
      {:ok, _} = create_project(%{tenant_id: tenant.id, name: "Test Project", position: "1"})

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(paginated_result.results)
    end

    test "returns an error if actor and tenant are not provided" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Project.list_paginated(page: [offset: 0, limit: 10, count: true])
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
