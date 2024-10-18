defmodule Omedis.Accounts.ProjectTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Project

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant()
    {:ok, group} = create_group(%{tenant_id: tenant.id})

    {:ok, _} =
      create_access_right(%{
        resource_name: "project",
        read: true,
        create: true,
        update: true,
        write: true,
        tenant_id: tenant.id,
        group_id: group.id
      })

    {:ok, _} = create_group_user(%{user_id: user.id, group_id: group.id})

    %{user: user, tenant: tenant}
  end

  describe "read/0" do
    test "returns all projects", %{tenant: tenant, user: user} do
      {:ok, project} = create_project(%{tenant_id: tenant.id})

      assert {:ok, projects} = Project.read(actor: user, tenant: tenant)
      refute Enum.empty?(projects)
      assert Enum.any?(projects, &(&1.id == project.id))
    end
  end

  describe "create/1" do
    test "creates a project with valid attributes", %{tenant: tenant, user: user} do
      attrs = %{name: "Test Project", tenant_id: tenant.id, position: "1"}

      assert {:ok, project} = Project.create(attrs, actor: user, tenant: tenant)
      assert project.name == "Test Project"
      assert project.tenant_id == tenant.id
      assert project.position == "1"
    end

    test "fails with invalid attributes", %{user: user, tenant: tenant} do
      assert {:error, changeset} =
               Project.create(%{name: nil}, actor: user, tenant: tenant)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :name and error.message == "must be present"
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :position and error.message == "must be present"
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :tenant_id and error.message == "must be present"
             end)
    end

    test "enforces unique_name identity constraint", %{tenant: tenant, user: user} do
      attrs = %{name: "Unique Project", tenant_id: tenant.id, position: "1"}
      assert {:ok, _project} = Project.create(attrs, actor: user, tenant: tenant)

      assert {:error, invalid_changeset} = Project.create(attrs, actor: user, tenant: tenant)

      assert Enum.any?(invalid_changeset.errors, fn error ->
               error.field == :name and error.message == "has already been taken"
             end)
    end

    test "enforces unique_position identity constraint", %{tenant: tenant, user: user} do
      attrs = %{name: "Project 1", tenant_id: tenant.id, position: "1"}
      assert {:ok, _project} = Project.create(attrs, actor: user, tenant: tenant)

      attrs = %{name: "Project 2", tenant_id: tenant.id, position: "1"}
      assert {:error, invalid_changeset} = Project.create(attrs, actor: user, tenant: tenant)

      assert Enum.any?(invalid_changeset.errors, fn error ->
               error.field == :position and error.message == "has already been taken"
             end)
    end
  end

  describe "update/2" do
    test "updates a project with valid attributes", %{tenant: tenant, user: user} do
      {:ok, project} = create_project(%{tenant_id: tenant.id})
      update_attrs = %{name: "Updated Project"}

      assert {:ok, updated_project} =
               Project.update(project.id, update_attrs, actor: user, tenant: tenant)

      assert updated_project.name == "Updated Project"
    end
  end

  describe "destroy/1" do
    test "deletes a project", %{tenant: tenant, user: user} do
      {:ok, project} = create_project(%{tenant_id: tenant.id})

      assert :ok = Project.destroy(project.id, actor: user, tenant: tenant)
      assert {:error, _} = Project.by_id(project.id, actor: user, tenant: tenant)
    end
  end

  describe "by_id/1" do
    test "returns a project by ID", %{tenant: tenant, user: user} do
      {:ok, project} = create_project(%{tenant_id: tenant.id})

      assert {:ok, fetched_project} = Project.by_id(project.id, actor: user, tenant: tenant)
      assert fetched_project.id == project.id
    end
  end

  describe "by_tenant_id/1" do
    test "returns projects for a specific tenant", %{tenant: tenant, user: user} do
      {:ok, project1} = create_project(%{tenant_id: tenant.id, name: "Project 1", position: "1"})
      {:ok, project2} = create_project(%{tenant_id: tenant.id, name: "Project 2", position: "2"})

      assert {:ok, tenant_projects} =
               Project.by_tenant_id(%{tenant_id: tenant.id}, actor: user, tenant: tenant)

      assert length(tenant_projects) == 2
      assert Enum.any?(tenant_projects, &(&1.id == project1.id))
      assert Enum.any?(tenant_projects, &(&1.id == project2.id))
    end
  end

  describe "list_paginated/1" do
    test "returns paginated projects", %{tenant: tenant, user: user} do
      for i <- 1..15 do
        create_project(%{tenant_id: tenant.id, name: "Project #{i}", position: "#{i}"})
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
  end

  describe "get_max_position_by_tenant_id/2" do
    test "returns the max position as an integer", %{tenant: tenant, user: user} do
      Enum.each(1..5, fn i ->
        create_project(%{tenant_id: tenant.id, position: "#{i}"})
      end)

      assert 5 == Project.get_max_position_by_tenant_id(tenant.id, actor: user, tenant: tenant)
    end
  end
end
