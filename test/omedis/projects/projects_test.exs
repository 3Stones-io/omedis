defmodule Omedis.Projects.ProjectsTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Projects

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, project} = create_project(organisation)

    %{
      organisation: organisation,
      owner: owner,
      project: project
    }
  end

  describe "get_max_position_by_organisation_id/2" do
    test "returns max position for projects in an organisation", %{
      organisation: organisation,
      owner: owner
    } do
      assert Projects.get_max_position_by_organisation_id(organisation.id,
               tenant: organisation,
               actor: owner
             ) != 0
    end
  end
end
