defmodule Omedis.LogCategoryTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.LogCategory

  require Ash.Query

  setup do
    {:ok, user} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: user.id})
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, project} = create_project(%{tenant_id: tenant.id})

    create_group_user(%{group_id: group.id, user_id: user.id})

    create_access_right(%{
      group_id: group.id,
      resource_name: "Tenant",
      tenant_id: tenant.id,
      read: true,
      write: true,
      update: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "Group",
      tenant_id: tenant.id,
      write: true,
      update: true
    })

    create_access_right(%{
      group_id: group.id,
      read: true,
      resource_name: "LogCategory",
      tenant_id: tenant.id,
      write: true,
      update: true
    })

    %{
      group: group,
      project: project,
      tenant: tenant,
      user: user
    }
  end

  describe "create/1" do
    test "user can create a log category if they are tenant owner", %{
      group: group,
      tenant: tenant,
      project: project,
      user: user
    } do
      attrs =
        %{
          name: "LogCategoryA",
          group_id: group.id,
          slug: "log_categorya",
          color_code: "#d62728",
          is_default: false,
          project_id: project.id
        }

      assert {:ok, log_category} =
               LogCategory.create(attrs, actor: user, tenant: tenant)

      assert log_category.slug == "log_categorya"
      assert log_category.position == 1
    end

    test "an authorized user can create log_categories", %{
      group: group,
      tenant: tenant,
      project: project
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      attrs =
        %{
          name: "LogCategoryA",
          group_id: group.id,
          slug: "log_categorya",
          color_code: "#d62728",
          is_default: false,
          project_id: project.id
        }

      assert {:ok, log_category} =
               LogCategory.create(attrs, actor: authorized_user, tenant: tenant)

      assert log_category.slug == "log_categorya"
      assert log_category.position == 1
    end

    test "unauthorised users cannot create log categories", %{
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        read: true,
        write: true,
        update: true
      })

      create_access_right(%{
        create: false,
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false
      })

      attrs = %{
        color_code: "#d62728",
        group_id: group.id,
        is_default: false,
        name: "LogCategoryA",
        project_id: project.id,
        slug: "log_categorya"
      }

      assert_raise Ash.Error.Forbidden, fn ->
        LogCategory.create!(attrs, actor: user, tenant: tenant)
      end
    end
  end

  describe "update/1" do
    test "user can update a log category if they are tenant owner", %{
      group: group,
      tenant: tenant,
      project: project,
      user: user
    } do
      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, updated_log_category} =
               LogCategory.update(
                 log_category,
                 %{
                   name: "Updated Name"
                 },
                 actor: user,
                 tenant: tenant
               )

      assert updated_log_category.name == "Updated Name"
    end

    test "an authorized user can update log categories", %{
      group: group,
      project: project,
      tenant: tenant
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, updated_log_category} =
               LogCategory.update(
                 log_category,
                 %{
                   name: "Updated Name"
                 },
                 actor: authorized_user,
                 tenant: tenant
               )

      assert updated_log_category.name == "Updated Name"
    end

    test "unauthorised users cannot update log categories", %{
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, log_category} = create_log_category(%{group_id: group.id, project_id: project.id})

      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      assert_raise Ash.Error.Forbidden, fn ->
        LogCategory.update!(log_category, %{name: "Updated Name"}, actor: user, tenant: tenant)
      end
    end
  end

  describe "move_up/1" do
    test "user can update the positions of a log categories if they are tenant owner", %{
      group: group,
      tenant: tenant,
      project: project,
      user: user
    } do
      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      target_category = Enum.find(categories, &(&1.position == 5))
      control_category = Enum.find(categories, &(&1.position == 4))

      assert {:ok, updated_category} =
               LogCategory.move_up(
                 target_category,
                 actor: user,
                 tenant: tenant
               )

      assert updated_category.position == 4

      {:ok, updated_control} =
        LogCategory
        |> Ash.Query.filter(id: control_category.id)
        |> Ash.read_one(tenant: tenant, actor: user)

      assert updated_control.position == 5
    end

    test "an authorized user can move a log category up", %{
      group: group,
      project: project,
      tenant: tenant
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      target_category = Enum.find(categories, &(&1.position == 5))
      control_category = Enum.find(categories, &(&1.position == 4))

      assert {:ok, updated_category} =
               LogCategory.move_up(
                 target_category,
                 actor: authorized_user,
                 tenant: tenant
               )

      assert updated_category.position == 4

      {:ok, updated_control} =
        LogCategory
        |> Ash.Query.filter(id: control_category.id)
        |> Ash.read_one(tenant: tenant, actor: authorized_user)

      assert updated_control.position == 5
    end

    test "unauthorised users cannot update the positions of log categories", %{
      user: user,
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      target_category = Enum.find(categories, &(&1.position == 5))

      {:error, %Ash.Error.Forbidden{}} =
        LogCategory.move_up(
          target_category,
          actor: user,
          tenant: tenant
        )
    end
  end

  describe "move_down/1" do
    test "user can update the positions of a log categories if they are tenant owner", %{
      group: group,
      tenant: tenant,
      project: project,
      user: user
    } do
      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      control_category = Enum.find(categories, &(&1.position == 5))
      target_category = Enum.find(categories, &(&1.position == 4))

      assert {:ok, updated_category} =
               LogCategory.move_down(
                 target_category,
                 actor: user,
                 tenant: tenant
               )

      assert updated_category.position == 5

      {:ok, updated_control} =
        LogCategory
        |> Ash.Query.filter(id: control_category.id)
        |> Ash.read_one(tenant: tenant, actor: user)

      assert updated_control.position == 4
    end

    test "an authorized user can move a log category up", %{
      group: group,
      project: project,
      tenant: tenant
    } do
      {:ok, authorized_user} = create_user()
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      control_category = Enum.find(categories, &(&1.position == 5))
      target_category = Enum.find(categories, &(&1.position == 4))

      assert {:ok, updated_category} =
               LogCategory.move_down(
                 target_category,
                 actor: authorized_user,
                 tenant: tenant
               )

      assert updated_category.position == 5

      {:ok, updated_control} =
        LogCategory
        |> Ash.Query.filter(id: control_category.id)
        |> Ash.read_one(tenant: tenant, actor: authorized_user)

      assert updated_control.position == 4
    end

    test "unauthorised users cannot update the positions of log categories", %{
      user: user,
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, group} = create_group(%{tenant_id: tenant.id})

      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        write: false,
        update: false
      })

      categories =
        Enum.map(1..10, fn _i ->
          {:ok, category} =
            create_log_category(%{
              group_id: group.id,
              project_id: project.id
            })

          category
        end)

      target_category = Enum.find(categories, &(&1.position == 5))

      {:error, %Ash.Error.Forbidden{}} =
        LogCategory.move_down(
          target_category,
          actor: user,
          tenant: tenant
        )
    end
  end

  describe "by_id/1" do
    test "returns a log category when user has read access rights", %{
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      create_project(%{tenant_id: tenant.id, group_id: group.id})
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        read: true
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: true
      })

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, fetched_category} =
               LogCategory.by_id(log_category.id, actor: authorized_user, tenant: tenant)

      assert log_category.id == fetched_category.id
    end

    test "returns a log category given a valid id", %{
      user: user,
      tenant: tenant,
      group: group,
      project: project
    } do
      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, fetched_category} =
               LogCategory.by_id(log_category.id, actor: user, tenant: tenant)

      assert log_category.id == fetched_category.id
    end

    test "returns an error when user has no access", %{
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      {:ok, log_category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: false
      })

      assert {:error, _} = LogCategory.by_id(log_category.id, actor: user, tenant: tenant)
    end
  end

  describe "list_paginated/1" do
    test "returns paginated log categories for users with read access", %{
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: true
      })

      Enum.each(1..15, fn _i ->
        {:ok, _} =
          create_log_category(%{
            group_id: group.id,
            project_id: project.id
          })
      end)

      assert {:ok, %{results: categories, count: total_count}} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 actor: authorized_user,
                 tenant: tenant,
                 page: [limit: 10, offset: 0]
               )

      assert length(categories) == 10
      assert total_count == 15
    end

    test "returns paginated log categories the user has access to", %{
      user: user,
      tenant: tenant,
      group: group,
      project: project
    } do
      Enum.each(1..15, fn _i ->
        {:ok, _} =
          create_log_category(%{
            group_id: group.id,
            project_id: project.id
          })
      end)

      assert {:ok, %{results: categories, count: total_count}} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 actor: user,
                 tenant: tenant,
                 page: [limit: 10, offset: 0]
               )

      assert length(categories) == 10
      assert total_count == 15

      assert {:ok, %{results: next_page}} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 actor: user,
                 tenant: tenant,
                 page: [limit: 10, offset: 10]
               )

      assert length(next_page) == 5
    end

    test "returns empty list when user has no access", %{
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      Enum.each(1..5, fn i ->
        {:ok, _} =
          create_log_category(%{
            name: "Category #{i}",
            slug: "category-#{i}",
            group_id: group.id,
            project_id: project.id
          })
      end)

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: false
      })

      assert {:ok, %{results: categories, count: 0}} =
               LogCategory.list_paginated(
                 %{group_id: group.id},
                 actor: user,
                 tenant: tenant
               )

      assert Enum.empty?(categories)
    end
  end

  describe "by_group_id_and_project_id/1" do
    test "returns log categories for users with read access", %{
      project: project
    } do
      {:ok, tenant} = create_tenant()
      {:ok, authorized_user} = create_user()
      {:ok, group} = create_group(%{tenant_id: tenant.id})
      create_group_user(%{group_id: group.id, user_id: authorized_user.id})

      create_access_right(%{
        group_id: group.id,
        resource_name: "Tenant",
        tenant_id: tenant.id,
        read: true
      })

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: true
      })

      {:ok, category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, categories} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: authorized_user,
                 tenant: tenant
               )

      assert length(categories) == 1
      assert hd(categories).id == category.id
    end

    test "returns log categories for specific group and project", %{
      user: user,
      tenant: tenant,
      group: group,
      project: project
    } do
      {:ok, category} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      assert {:ok, categories} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: user,
                 tenant: tenant
               )

      assert length(categories) == 1
      assert hd(categories).id == category.id
    end

    test "returns empty list when user has no access", %{
      user: user,
      group: group,
      project: project
    } do
      {:ok, tenant} = create_tenant()

      {:ok, _} =
        create_log_category(%{
          group_id: group.id,
          project_id: project.id
        })

      create_access_right(%{
        group_id: group.id,
        resource_name: "LogCategory",
        tenant_id: tenant.id,
        read: false
      })

      assert {:ok, []} =
               LogCategory.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: user,
                 tenant: tenant
               )
    end
  end
end
