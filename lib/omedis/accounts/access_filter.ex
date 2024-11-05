defmodule Omedis.Accounts.AccessFilter do
  @moduledoc """
  This policy filter is used to filter resources based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering resources based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)
  def filter(_actor, %{subject: %{tenant: nil}}, _options), do: expr(false)

  def filter(actor, %{subject: %{tenant: organisation}}, _options)
      when actor.id == organisation.owner_id do
    expr(true)
  end

  def filter(actor, %{subject: %{tenant: organisation}}, _options) do
    expr(
      exists(
        access_rights,
        organisation_id == ^organisation.id and
          read == true and
          exists(group.group_users, user_id == ^actor.id)
      ) and exists(organisation, id == ^organisation.id)
    )
  end
end
