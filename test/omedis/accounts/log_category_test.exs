defmodule Omedis.Accounts.LogCategoryTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.LogCategory

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, project} = create_project(%{organisation_id: organisation.id})
    {:ok, authorized_user} = create_user()

    {:ok, _} = create_group_user(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        organisation_id: organisation.id,
        write: true
      })

    {:ok, _} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id,
        write: true
      })

    {:ok, user} = create_user()
    {:ok, group_2} = create_group()
    {:ok, _} = create_group_user(%{group_id: group_2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(%{
        group_id: group_2.id,
        read: true,
        resource_name: "Organisation",
        organisation_id: organisation.id,
        write: true
      })

    %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project,
      authorized_user: authorized_user,
      user: user
    }
  end

  describe "create/2" do
    test "organisation owner can create a log category", %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Category",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-category"
      }

      assert {:ok, category} = LogCategory.create(attrs, actor: owner, tenant: organisation)
      assert category.name == "Test Category"
      assert category.color_code == "#FF0000"
      assert category.position == 1
    end

    test "authorized user can create a log category", %{
      authorized_user: authorized_user,
      tenant: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Category",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-category"
      }

      assert {:ok, category} =
               LogCategory.create(attrs, actor: authorized_user, tenant: organisation)

      assert category.name == "Test Category"
    end

    test "unauthorized user cannot create a log category", %{
      user: user,
      tenant: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Category",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-category"
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               LogCategory.create(attrs, actor: user, tenant: organisation)
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        group_id: group.id,
        project_id: project.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               LogCategory.create(attrs, actor: owner, tenant: organisation)
    end
  end

  describe "update/2" do
    test "organisation owner can update a log category", %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:ok, updated_category} =
               LogCategory.update(category, %{name: "Updated Category"},
                 actor: owner,
                 tenant: organisation
               )

      assert updated_category.name == "Updated Category"
    end

    test "authorized user can update a log category", %{
      authorized_user: authorized_user,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:ok, updated_category} =
               LogCategory.update(category, %{name: "Updated Category"},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert updated_category.name == "Updated Category"
    end

    test "unauthorized user cannot update a log category", %{
      user: user,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:error, %Ash.Error.Forbidden{}} =
               LogCategory.update(category, %{name: "Updated Category"},
                 actor: user,
                 tenant: organisation
               )
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      invalid_attrs = %{
        name: "",
        color_code: "invalid-color"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               LogCategory.update(category, invalid_attrs, actor: owner, tenant: organisation)
    end
  end

  describe "by_id/2" do
    test "returns log category for organisation owner", %{
      owner: owner,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:ok, found_category} =
               LogCategory.by_id(category.id, actor: owner, tenant: organisation)

      assert found_category.id == category.id
    end

    test "returns log category for authorized user", %{
      authorized_user: authorized_user,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:ok, found_category} =
               LogCategory.by_id(category.id, actor: authorized_user, tenant: organisation)

      assert found_category.id == category.id
    end

    test "returns error for unauthorized user", %{
      user: user,
      tenant: organisation,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-category"
        })

      assert {:error, %Ash.Error.Query.NotFound{}} =
               LogCategory.by_id(category.id, actor: user, tenant: organisation)
    end
  end

  describe "list_paginated/1" do
    setup %{group: group, project: project} do
      Enum.each(1..15, fn _ ->
        {:ok, _} =
          create_log_category(%{
            group_id: group.id,
            project_id: project.id
          })
      end)

      :ok
    end

    test "returns paginated log categories for organisation owner", %{
      group: group,
      owner: owner,
      tenant: organisation
    } do
      assert {:ok, paginated_result} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: owner,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "returns paginated log categories for authorized user", %{
      authorized_user: authorized_user,
      group: group,
      tenant: organisation
    } do
      assert {:ok, paginated_result} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "does not return paginated log categories for unauthorized user", %{
      group: group,
      tenant: organisation,
      user: user
    } do
      assert {:ok, paginated_result} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(paginated_result.results)
    end
  end

  describe "by_group_id_and_project_id/2" do
    setup %{group: group, project: project} do
      {:ok, category} =
        create_log_category(%{
          name: "Test Category",
          group_id: group.id,
          project_id: project.id
        })

      %{category: category}
    end

    test "returns log categories for specific group and project for organisation owner", %{
      category: category,
      group: group,
      owner: owner,
      project: project,
      tenant: organisation
    } do
      assert {:ok, categories} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: owner,
                 tenant: organisation
               )

      assert length(categories) == 1
      assert hd(categories).id == category.id
    end

    test "returns log categories for specific group and project for an authorized user", %{
      authorized_user: authorized_user,
      category: category,
      group: group,
      project: project,
      tenant: organisation
    } do
      assert {:ok, categories} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(categories) == 1
      assert hd(categories).id == category.id
    end

    test "does not return log categories for specific group and project for an unauthorized user",
         %{
           group: group,
           project: project,
           tenant: organisation,
           user: user
         } do
      assert {:ok, categories} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(categories)
    end
  end

  describe "move_up/2" do
    setup %{group: group, project: project} do
      {:ok, category1} =
        create_log_category(%{
          name: "Category 1",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0001",
          slug: "category-1"
        })

      {:ok, category2} =
        create_log_category(%{
          name: "Category 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002",
          slug: "category-2"
        })

      %{category1: category1, category2: category2}
    end

    test "organisation owner can move a category up in position", %{
      category1: category1,
      category2: category2,
      owner: owner,
      tenant: organisation
    } do
      assert {:ok, moved_category} =
               LogCategory.move_up(category2, actor: owner, tenant: organisation)

      assert moved_category.position == 1

      {:ok, updated_category1} =
        LogCategory.by_id(category1.id, actor: owner, tenant: organisation)

      assert updated_category1.position == 2
    end

    test "authorized user can move a category up in position", %{
      authorized_user: authorized_user,
      category1: category1,
      category2: category2,
      tenant: organisation
    } do
      assert {:ok, moved_category} =
               LogCategory.move_up(category2, actor: authorized_user, tenant: organisation)

      assert moved_category.position == 1

      {:ok, updated_category1} =
        LogCategory.by_id(category1.id, actor: authorized_user, tenant: organisation)

      assert updated_category1.position == 2
    end

    test "unauthorized user cannot move a category up in position", %{
      category2: category2,
      tenant: organisation,
      user: user
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               LogCategory.move_up(category2, actor: user, tenant: organisation)
    end

    test "does nothing when category is at top position", %{
      category1: category1,
      owner: owner,
      tenant: organisation
    } do
      assert {:ok, unchanged_category} =
               LogCategory.move_up(category1, actor: owner, tenant: organisation)

      assert unchanged_category.position == 1
    end
  end

  describe "move_down/2" do
    setup %{group: group, project: project} do
      {:ok, category2} =
        create_log_category(%{
          name: "Category 1",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0001",
          slug: "category-1"
        })

      {:ok, category1} =
        create_log_category(%{
          name: "Category 2",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0002",
          slug: "category-2"
        })

      %{category1: category1, category2: category2}
    end

    test "organisation owner can move a category down in position", %{
      category1: category1,
      category2: category2,
      owner: owner,
      tenant: organisation
    } do
      assert {:ok, moved_category} =
               LogCategory.move_down(category2, actor: owner, tenant: organisation)

      assert moved_category.position == 2

      {:ok, updated_category1} =
        LogCategory.by_id(category1.id, actor: owner, tenant: organisation)

      assert updated_category1.position == 1
    end

    test "authorized user can move a category down in position", %{
      authorized_user: authorized_user,
      category1: category1,
      category2: category2,
      tenant: organisation
    } do
      assert {:ok, moved_category} =
               LogCategory.move_down(category2, actor: authorized_user, tenant: organisation)

      assert moved_category.position == 2

      {:ok, updated_category1} =
        LogCategory.by_id(category1.id, actor: authorized_user, tenant: organisation)

      assert updated_category1.position == 1
    end

    test "unauthorized user cannot move a category down in position", %{
      category2: category2,
      tenant: organisation,
      user: user
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               LogCategory.move_down(category2, actor: user, tenant: organisation)
    end

    test "does nothing when category is at bottom position", %{
      category1: category1,
      owner: owner,
      tenant: organisation
    } do
      assert {:ok, unchanged_category} =
               LogCategory.move_down(category1, actor: owner, tenant: organisation)

      assert unchanged_category.position == 2
    end
  end
end
