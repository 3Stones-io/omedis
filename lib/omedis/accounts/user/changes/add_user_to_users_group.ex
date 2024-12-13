defmodule Omedis.Accounts.User.Changes.AddUserToUsersGroup do
  @moduledoc """
  Adds a user to the users group if they registered via an invitation.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.GroupMembership
  alias Omedis.Accounts.Organisation

  @impl true
  def change(
        %{attributes: %{current_organisation_id: current_organisation_id}} = changeset,
        _opts,
        _context
      )
      when not is_nil(current_organisation_id) do
    Ash.Changeset.after_action(changeset, fn
      _changeset, user ->
        {:ok, current_organisation} =
          Organisation.by_id(current_organisation_id, authorize?: false)

        {:ok, _} = add_user_to_users_group(user, current_organisation)

        {:ok, user}
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp add_user_to_users_group(user, current_organisation) do
    with {:ok, [users_group]} <- get_users_group(current_organisation) do
      GroupMembership.create(
        %{
          group_id: users_group.id,
          user_id: user.id
        },
        authorize?: false,
        tenant: current_organisation,
        upsert_identity: :unique_group_membership,
        upsert?: true,
        upsert_fields: []
      )
    end
  end

  defp get_users_group(current_organisation) do
    Group
    |> Ash.Query.filter(slug: "users", organisation_id: current_organisation.id)
    |> Ash.read(authorize?: false, tenant: current_organisation)
  end
end
