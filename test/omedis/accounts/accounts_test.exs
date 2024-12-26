defmodule Omedis.AccountsTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Accounts
  alias Omedis.Accounts.Organisation

  setup do
    {:ok, owner} = create_user()
    organisation = fetch_users_organisation(owner.id)

    %{
      owner: owner,
      organisation: organisation
    }
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
