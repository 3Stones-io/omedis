defmodule Omedis.Accounts.AccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  require Ash.Query

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)
  def filter(_actor, %{subject: %{tenant: nil}}, _options), do: expr(false)

  def filter(actor, %{subject: %{tenant: organisation}}, _options) do
    actor_is_admin = check_if_actor_is_admin(actor, organisation)

    if actor_is_admin do
      expr(true)
    else
      expr(
        exists(
          access_rights,
          organisation_id == ^organisation.id and
            read == true and
            exists(group.group_memberships, user_id == ^actor.id)
        )
      )
    end
  end

  defp check_if_actor_is_admin(actor, organisation) do
    Omedis.Accounts.AccessRight
    |> Ash.Query.filter(resource_name: "*")
    |> Ash.Query.filter(exists(group.group_memberships, user_id == ^actor.id))
    |> Ash.exists?(actor: actor, tenant: organisation)
  end
end
