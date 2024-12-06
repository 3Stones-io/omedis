defmodule Omedis.Accounts.ProjectTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Accounts.Project

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
        resource_name: "Project",
        create: true,
        update: true
      })

    %{
      authorized_user: authorized_user,
      group: group,
      owner: owner,
      organisation: organisation,
      user: user
    }
  end

  describe "list_paginated/1" do
    test "returns projects if user is the organisation owner" do
      {:ok, owner} = create_user()
      {:ok, another_user} = create_user()
      organisation = fetch_users_organisation(owner.id)
      {:ok, group} = create_group(organisation)

      {:ok, _} =
        create_group_membership(organisation, %{group_id: group.id, user_id: another_user.id})

      {:ok, _} =
        create_access_right(organisation, %{
          group_id: group.id,
          read: true,
          resource_name: "Project"
        })

      {:ok, project} =
        create_project(organisation, %{name: "Test Project"})

      assert {:ok, %{results: projects}} =
               Project.list_paginated(
                 page: [offset: 0, limit: 10, count: true],
                 actor: owner,
                 tenant: organisation
               )

      # An additional default project is created when an organisation is created
      assert length(projects) == 2
      assert List.last(projects).id == project.id
    end

    test "returns paginated list of projects the user has access to" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()
      {:ok, other_organisation} = create_organisation()
      {:ok, group} = create_group(organisation)
      {:ok, other_group} = create_group(other_organisation)
      {:ok, _} = create_group_membership(organisation, %{user_id: user.id, group_id: group.id})

      {:ok, _} =
        create_group_membership(organisation, %{user_id: user.id, group_id: other_group.id})

      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Project",
          read: true,
          group_id: group.id
        })

      # Create another access right with read set to false
      {:ok, _} =
        create_access_right(other_organisation, %{
          resource_name: "Project",
          read: false,
          group_id: other_group.id
        })

      for i <- 1..10 do
        {:ok, _} =
          create_project(organisation, %{
            name: "Accessible Project #{i}"
          })
      end

      for i <- 1..10 do
        {:ok, _} =
          create_project(other_organisation, %{
            name: "Inaccessible Project #{i}"
          })
      end

      # Return projects the user has access to
      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 20, count: true],
                 actor: user,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
      assert paginated_result.count == 10
      assert Enum.all?(paginated_result.results, &(&1.organisation_id == organisation.id))

      assert Enum.all?(
               paginated_result.results,
               &String.starts_with?(&1.name, "Accessible Project")
             )

      # Return an empty list if the user doesn't have access
      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, limit: 20, count: true],
                 actor: user,
                 tenant: other_organisation
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
    end

    test "returns an empty list for a user without access" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)

      # Create access right with read set to false
      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Project",
          read: false,
          group_id: group.id
        })

      {:ok, _} = create_group_membership(organisation, %{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(organisation, %{name: "Project X"})

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
    end

    test "returns projects only for the specified organisation" do
      {:ok, user} = create_user()
      {:ok, organisation_1} = create_organisation()
      {:ok, organisation_2} = create_organisation()
      {:ok, group_1} = create_group(organisation_1)
      {:ok, group_2} = create_group(organisation_2)

      {:ok, _} =
        create_access_right(organisation_1, %{
          resource_name: "Project",
          read: true,
          group_id: group_1.id
        })

      {:ok, _} =
        create_access_right(organisation_2, %{
          resource_name: "Project",
          read: true,
          group_id: group_2.id
        })

      {:ok, _} =
        create_group_membership(organisation_1, %{user_id: user.id, group_id: group_1.id})

      {:ok, _} =
        create_group_membership(organisation_2, %{user_id: user.id, group_id: group_2.id})

      for i <- 1..5 do
        {:ok, _} =
          create_project(organisation_1, %{
            name: "T1 Project #{i}"
          })
      end

      for i <- 1..3 do
        {:ok, _} =
          create_project(organisation_2, %{
            name: "T2 Project #{i}"
          })
      end

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: organisation_1
               )

      assert length(paginated_result.results) == 5
      assert paginated_result.count == 5
      assert Enum.all?(paginated_result.results, &(&1.organisation_id == organisation_1.id))

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: organisation_2
               )

      assert length(paginated_result.results) == 3
      assert paginated_result.count == 3
      assert Enum.all?(paginated_result.results, &(&1.organisation_id == organisation_2.id))
    end

    test "returns an error if the actor is not provided" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)

      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Project",
          read: true,
          group_id: group.id
        })

      {:ok, _} = create_group_membership(organisation, %{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(organisation, %{name: "Project X"})

      assert {:error, %Ash.Error.Forbidden{} = _error} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 tenant: organisation
               )
    end

    test "returns an error if the organisation is not provided" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)

      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Project",
          read: true,
          group_id: group.id
        })

      {:ok, _} = create_group_membership(organisation, %{user_id: user.id, group_id: group.id})
      {:ok, _} = create_project(organisation, %{name: "Project X"})

      assert {:error, %Ash.Error.Invalid{} = _error} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user
               )
    end

    test "returns empty list for user without group membership" do
      {:ok, user} = create_user()
      {:ok, organisation} = create_organisation()
      {:ok, group} = create_group(organisation)

      {:ok, _} =
        create_access_right(organisation, %{
          resource_name: "Project",
          read: true,
          group_id: group.id
        })

      {:ok, _} = create_project(organisation, %{name: "Project X"})

      assert {:ok, paginated_result} =
               Project.list_paginated(
                 page: [offset: 0, count: true],
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(paginated_result.results)
      assert paginated_result.count == 0
    end
  end

  describe "create/1" do
    test "organisation owner can create a project", %{owner: owner, organisation: organisation} do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "New Project")

      assert {:ok, project} = Project.create(attrs, actor: owner, tenant: organisation)
      assert project.name == "New Project"
    end

    test "authorized user can create a project", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "New Project")

      assert {:ok, project} = Project.create(attrs, actor: authorized_user, tenant: organisation)
      assert project.name == "New Project"
    end

    test "unauthorized user cannot create a project", %{user: user, organisation: organisation} do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "New Project")

      assert {:error, %Ash.Error.Forbidden{}} =
               Project.create(attrs, actor: user, tenant: organisation)
    end
  end

  describe "update/1" do
    test "organisation owner can update a project", %{owner: owner, organisation: organisation} do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "Test Project")

      {:ok, project} =
        Project.create(attrs,
          actor: owner,
          tenant: organisation
        )

      assert {:ok, updated_project} =
               Project.update(project, %{name: "Updated Project"},
                 actor: owner,
                 tenant: organisation
               )

      assert updated_project.name == "Updated Project"
    end

    test "authorized user can update a project", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "Test Project")

      {:ok, project} =
        Project.create(attrs,
          actor: authorized_user,
          tenant: organisation
        )

      assert {:ok, updated_project} =
               Project.update(project, %{name: "Updated Project"},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert updated_project.name == "Updated Project"
    end

    test "unauthorized user cannot update a project", %{
      authorized_user: authorized_user,
      user: user,
      organisation: organisation
    } do
      attrs =
        Project
        |> attrs_for(organisation)
        |> Map.put(:name, "Test Project")

      {:ok, project} =
        Project.create(attrs,
          actor: authorized_user,
          tenant: organisation
        )

      assert {:error, %Ash.Error.Forbidden{}} =
               Project.update(project, %{name: "Updated Project"},
                 actor: user,
                 tenant: organisation
               )
    end
  end
end
