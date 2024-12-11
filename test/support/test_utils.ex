defmodule Omedis.TestUtils do
  @moduledoc false

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Organisation

  require Ash.Query

  def time_after(seconds_offset) do
    DateTime.utc_now()
    |> DateTime.add(seconds_offset)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end

  def fetch_users_organisation(user_id) do
    Organisation
    |> Ash.Query.filter(owner_id: user_id)
    |> Ash.read_one!(authorize?: false)
  end

  def admin_group(organisation_id) do
    Group
    |> Ash.Query.filter(name: "Administrators")
    |> Ash.read_one!(tenant: organisation_id, authorize?: false)
  end
end
