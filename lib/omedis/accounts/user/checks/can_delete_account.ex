defmodule Omedis.Accounts.User.Checks.CanDeleteAccount do
  @moduledoc """
  A policy that checks if a user can delete their own account.
  """

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Organisation
  alias Omedis.Groups
  alias Omedis.Groups.GroupMembership

  def describe(_options), do: "User can delete their own account"

  def match?(nil, _context, _options), do: false

  def match?(actor, _context, _options) do
    owns_organisation?(actor) and not_the_only_admin?(actor)
  end

  defp not_the_only_admin?(actor) do
    organisation = owner_organisation(actor)

    admin_group =
      Groups.get_group_by_slug!("administrators", actor: actor, tenant: organisation)

    admin_group_membership_count =
      GroupMembership
      |> filter(group_id == ^admin_group.id)
      |> Ash.count!(actor: actor, tenant: organisation)

    admin_group_membership_count > 1
  end

  defp owns_organisation?(actor) do
    Organisation
    |> filter(owner_id == ^actor.id)
    |> Ash.exists?(actor: actor)
  end

  defp owner_organisation(actor) do
    Organisation
    |> filter(owner_id == ^actor.id)
    |> Ash.read_one!(actor: actor)
  end
end
