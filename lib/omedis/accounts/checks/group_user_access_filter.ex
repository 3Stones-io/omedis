defmodule Omedis.Accounts.GroupUserAccessFilter do
  @moduledoc """
  This policy filter is used to filter group_users based on user access rights.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "Filtering group_users based on user access rights"
  end

  def filter(nil, _context, _options), do: expr(false)

  def filter(actor, context, _options) do
    organisation = context.subject.tenant

    case organisation do
      nil ->
        expr(false)

      organisation ->
        expr(
          (exists(
             access_rights,
             organisation_id == ^organisation.id and
               read == true and
               exists(group.group_users, user_id == ^actor.id)
           ) and
             exists(group, organisation_id == ^organisation.id)) or
            group.organisation.owner_id == ^actor.id
        )
    end
  end
end
