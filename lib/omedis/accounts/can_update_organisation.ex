defmodule Omedis.Accounts.CanUpdateOrganisation do
  @moduledoc """
  Determines whether a user can update an organisation.
  User either needs to be the owner of the organisation or have write access to the organisation through a group.
  """
  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.AccessRights.AccessRight

  def describe(_options) do
    "User can update or destroy an organisation if they are the owner or have access through a group."
  end

  def match?(nil, _context, _opts), do: false
  def match?(_actor, %{subject: %{data: nil}}, _opts), do: false

  def match?(actor, %{subject: %{data: organisation, action: %{type: action}}}, _opts) do
    AccessRight
    |> filter(
      resource_name == "Organisation" and exists(group.group_memberships, user_id == ^actor.id)
    )
    |> filter_by_action(action)
    |> Ash.exists?(tenant: organisation)
  end

  defp filter_by_action(query, :update), do: filter(query, update == true)
  defp filter_by_action(query, :destroy), do: filter(query, destroy == true)
end
