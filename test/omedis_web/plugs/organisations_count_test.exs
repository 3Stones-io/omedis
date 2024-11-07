defmodule OmedisWeb.Plugs.OrganisationsCountTest do
  use OmedisWeb.ConnCase, async: true

  alias OmedisWeb.Plugs.OrganisationsCount

  describe "call/2" do
    test "when user is logged in assigns the organisations_count with the number of organisations user has access to",
         %{conn: conn} do
      %{conn: conn, user: user_1} = register_and_log_in_user(%{conn: conn})

      {:ok, user_2} = create_user()
      {:ok, user_3} = create_user()

      {:ok, group_1} = create_group()
      {:ok, group_2} = create_group()
      {:ok, group_3} = create_group()

      {:ok, _group_membership_1} =
        create_group_membership(%{group_id: group_1.id, user_id: user_1.id})

      {:ok, _group_membership_2} =
        create_group_membership(%{group_id: group_2.id, user_id: user_1.id})

      {:ok, _group_membership_3} =
        create_group_membership(%{group_id: group_1.id, user_id: user_2.id})

      {:ok, _group_membership_4} =
        create_group_membership(%{group_id: group_2.id, user_id: user_3.id})

      {:ok, organisation_1} = create_organisation()
      {:ok, organisation_2} = create_organisation()
      {:ok, organisation_3} = create_organisation()
      {:ok, _organisation_4} = create_organisation(%{owner_id: user_1.id})

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          organisation_id: organisation_1.id,
          read: true,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          organisation_id: organisation_2.id,
          read: true,
          resource_name: "User"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_1.id,
          organisation_id: organisation_3.id,
          read: false,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_2.id,
          organisation_id: organisation_1.id,
          read: true,
          resource_name: "User"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          organisation_id: organisation_1.id,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          organisation_id: organisation_2.id,
          resource_name: "Organisation"
        })

      {:ok, _} =
        create_access_right(%{
          group_id: group_3.id,
          organisation_id: organisation_3.id,
          resource_name: "organisation"
        })

      conn = OrganisationsCount.call(conn, [])

      assert conn.assigns[:organisations_count] == 2
    end

    test "when user is not logged in organisations_count is 0", %{conn: conn} do
      conn = OrganisationsCount.call(conn, [])

      assert conn.assigns[:organisations_count] == 0
    end
  end
end
