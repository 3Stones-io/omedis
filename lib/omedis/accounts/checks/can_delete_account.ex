defmodule Omedis.Accounts.CanDeleteAccount do
  @moduledoc """
  A policy that checks if a user can delete their own account.
  """

  use Ash.Policy.SimpleCheck

  import Ash.Query

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.GroupMembership
  alias Omedis.Accounts.Organisation

  def describe(_options), do: "User can delete their own account"

  def match?(nil, _context, _options), do: false

  def match?(actor, _context, _options) do
    Ash.exists?(
      filter(Organisation, owner_id == ^actor.id),
      authorize?: false
    ) and check_admin_group_membership(actor)
  end

  defp check_admin_group_membership(actor) do
    organisation = owner_organisation(actor)

    admin_group =
      Group.by_slug!("administrators", actor: actor, tenant: organisation)

    admin_group_membership_count =
      GroupMembership
      |> filter(group_id == ^admin_group.id)
      |> Ash.count!(actor: actor, tenant: organisation)

    admin_group_membership_count > 1
  end

  defp owner_organisation(actor) do
    Organisation
    |> filter(owner_id == ^actor.id)
    |> Ash.read_one!(actor: actor)
  end
end
