defmodule Omedis.AccountsTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures
  import Omedis.TestUtils

  alias Omedis.Accounts
  alias Omedis.Accounts.Organisation

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)
    {:ok, _project} = create_project(organisation)

    %{
      owner: owner,
      organisation: organisation
    }
  end

  describe "get_max_position_by_organisation_id/2" do
    test "returns max position for projects in an organisation", %{
      organisation: organisation,
      owner: owner
    } do
      assert Accounts.get_max_position_by_organisation_id(organisation.id,
               tenant: organisation,
               actor: owner
             ) != 0
    end
  end

  describe "slug_exists?/3" do
    test "checks if a slug exists for a resource", %{organisation: organisation, owner: owner} do
      assert Accounts.slug_exists?(Organisation, [slug: organisation.slug], actor: owner)
    end

    test "returns false if a slug does not exist for a resource", %{owner: owner} do
      refute Accounts.slug_exists?(Organisation, [slug: "non-existent-slug"], actor: owner)
    end
  end
end
