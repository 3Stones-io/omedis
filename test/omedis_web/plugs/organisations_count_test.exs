defmodule OmedisWeb.Plugs.OrganisationsCountTest do
  use OmedisWeb.ConnCase, async: true

  alias OmedisWeb.Plugs.OrganisationsCount

  describe "call/2" do
    test "when user is logged in assigns the organisations_count with the number of organisations user has access to",
         %{conn: conn} do
      %{conn: conn, user: user_1} = register_and_log_in_user(%{conn: conn})

      {:ok, user_2} = create_user()
      {:ok, user_3} = create_user()

      {:ok, organisation_1} = create_organisation()
      {:ok, organisation_2} = create_organisation()
      {:ok, organisation_3} = create_organisation()

      {:ok, group_1} = create_group(organisation_1)
      {:ok, group_2} = create_group(organisation_2)
      {:ok, group_3} = create_group(organisation_3)

      {:ok, _group_membership_1} =
        create_group_membership(organisation_1, %{group_id: group_1.id, user_id: user_1.id})

      {:ok, _group_membership_2} =
        create_group_membership(organisation_2, %{group_id: group_2.id, user_id: user_1.id})

      {:ok, _group_membership_3} =
        create_group_membership(organisation_1, %{group_id: group_1.id, user_id: user_2.id})

      {:ok, _group_membership_4} =
        create_group_membership(organisation_2, %{group_id: group_2.id, user_id: user_3.id})

      {:ok, _} =
        create_access_right(organisation_1, %{
          group_id: group_1.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(organisation_1, %{
          group_id: group_1.id,
          read: true,
          resource_name: "User"
        })

      {:ok, _} =
        create_access_right(organisation_1, %{
          group_id: group_1.id,
          read: false,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(organisation_2, %{
          group_id: group_2.id,
          read: true,
          resource_name: "User"
        })

      {:ok, _} =
        create_access_right(organisation_1, %{group_id: group_3.id, resource_name: "Organisation"})

      {:ok, _} =
        create_access_right(organisation_2, %{group_id: group_3.id, resource_name: "Organisation"})

      {:ok, _} =
        create_access_right(organisation_3, %{group_id: group_3.id, resource_name: "Organisation"})

      conn = OrganisationsCount.call(conn, [])

      assert conn.assigns[:organisations_count] == 2
    end

    test "when user is not logged in organisations_count is 0", %{conn: conn} do
      conn = OrganisationsCount.call(conn, [])

      assert conn.assigns[:organisations_count] == 0
    end
  end
end
