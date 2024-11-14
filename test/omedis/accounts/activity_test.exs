defmodule Omedis.Accounts.ActivityTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Activity

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id}, actor: owner)
    {:ok, group} = create_group(organisation)
    {:ok, project} = create_project(organisation)
    {:ok, authorized_user} = create_user()

    {:ok, _} =
      create_group_membership(organisation, %{group_id: group.id, user_id: authorized_user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Activity",
        write: true
      })

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group.id,
        read: true,
        resource_name: "Organisation",
        write: true
      })

    {:ok, user} = create_user()
    {:ok, group_2} = create_group(organisation)
    {:ok, _} = create_group_membership(organisation, %{group_id: group_2.id, user_id: user.id})

    {:ok, _} =
      create_access_right(organisation, %{
        group_id: group_2.id,
        read: true,
        resource_name: "Organisation",
        write: true
      })

    %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project,
      authorized_user: authorized_user,
      user: user
    }
  end

  describe "create/2" do
    test "organisation owner can create an activity", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-activity"
      }

      assert {:ok, activity} = Activity.create(attrs, actor: owner, tenant: organisation)
      assert activity.name == "Test Activity"
      assert activity.color_code == "#FF0000"
      assert activity.position == 1
    end

    test "authorized user can create an activity", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-activity"
      }

      assert {:ok, activity} =
               Activity.create(attrs, actor: authorized_user, tenant: organisation)

      assert activity.name == "Test Activity"
    end

    test "unauthorized user cannot create an activity", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        name: "Test Activity",
        group_id: group.id,
        project_id: project.id,
        color_code: "#FF0000",
        slug: "test-activity"
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               Activity.create(attrs, actor: user, tenant: organisation)
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      attrs = %{
        group_id: group.id,
        project_id: project.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Activity.create(attrs, actor: owner, tenant: organisation)
    end
  end

  describe "update/2" do
    test "organisation owner can update an activity", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:ok, updated_activity} =
               Activity.update(activity, %{name: "Updated Activity"},
                 actor: owner,
                 tenant: organisation
               )

      assert updated_activity.name == "Updated Activity"
    end

    test "authorized user can update an activity", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:ok, updated_activity} =
               Activity.update(activity, %{name: "Updated Activity"},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert updated_activity.name == "Updated Activity"
    end

    test "unauthorized user cannot update an activity", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:error, %Ash.Error.Forbidden{}} =
               Activity.update(activity, %{name: "Updated Activity"},
                 actor: user,
                 tenant: organisation
               )
    end

    test "returns error with invalid attributes", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      invalid_attrs = %{
        name: "",
        color_code: "invalid-color"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Activity.update(activity, invalid_attrs, actor: owner, tenant: organisation)
    end
  end

  describe "by_id/2" do
    test "returns activity for organisation owner", %{
      owner: owner,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:ok, found_activity} =
               Activity.by_id(activity.id, actor: owner, tenant: organisation)

      assert found_activity.id == activity.id
    end

    test "returns activity for authorized user", %{
      authorized_user: authorized_user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:ok, found_activity} =
               Activity.by_id(activity.id, actor: authorized_user, tenant: organisation)

      assert found_activity.id == activity.id
    end

    test "returns error for unauthorized user", %{
      user: user,
      organisation: organisation,
      group: group,
      project: project
    } do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id,
          color_code: "#FF0000",
          slug: "test-activity"
        })

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Activity.by_id(activity.id, actor: user, tenant: organisation)
    end
  end

  describe "list_paginated/1" do
    setup %{group: group, organisation: organisation} do
      Enum.each(1..15, fn _ ->
        {:ok, _} =
          create_activity(organisation, %{
            group_id: group.id
          })
      end)

      :ok
    end

    test "returns paginated activities for organisation owner", %{
      group: group,
      owner: owner,
      organisation: organisation
    } do
      assert {:ok, paginated_result} =
               Activity.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: owner,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "returns paginated activities for authorized user", %{
      authorized_user: authorized_user,
      group: group,
      organisation: organisation
    } do
      assert {:ok, paginated_result} =
               Activity.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(paginated_result.results) == 10
    end

    test "does not return paginated activities for unauthorized user", %{
      group: group,
      organisation: organisation,
      user: user
    } do
      assert {:ok, paginated_result} =
               Activity.list_paginated(
                 %{group_id: group.id},
                 page: [offset: 0, limit: 10],
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(paginated_result.results)
    end
  end

  describe "by_group_id_and_project_id/2" do
    setup %{group: group, organisation: organisation, project: project} do
      {:ok, activity} =
        create_activity(organisation, %{
          name: "Test Activity",
          group_id: group.id,
          project_id: project.id
        })

      %{activity: activity}
    end

    test "returns activities for specific group and project for organisation owner", %{
      activity: activity,
      group: group,
      owner: owner,
      project: project,
      organisation: organisation
    } do
      assert {:ok, activities} =
               Activity.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: owner,
                 tenant: organisation
               )

      assert length(activities) == 1
      assert hd(activities).id == activity.id
    end

    test "returns activities for specific group and project for an authorized user", %{
      authorized_user: authorized_user,
      activity: activity,
      group: group,
      project: project,
      organisation: organisation
    } do
      assert {:ok, activities} =
               Activity.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: authorized_user,
                 tenant: organisation
               )

      assert length(activities) == 1
      assert hd(activities).id == activity.id
    end

    test "does not return activities for specific group and project for an unauthorized user",
         %{
           group: group,
           project: project,
           organisation: organisation,
           user: user
         } do
      assert {:ok, activities} =
               Activity.by_group_id_and_project_id(
                 %{group_id: group.id, project_id: project.id},
                 actor: user,
                 tenant: organisation
               )

      assert Enum.empty?(activities)
    end
  end
end
