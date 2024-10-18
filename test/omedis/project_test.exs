defmodule Omedis.Accounts.ProjectTest do
  use Omedis.DataCase, async: true

  describe "list_paginated/1" do
    alias Omedis.Accounts.Project

    test "returns paginated list of projects" do
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
  end
end
