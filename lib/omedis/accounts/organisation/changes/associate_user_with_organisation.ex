defmodule Omedis.Accounts.Organisation.Changes.AssociateUserWithOrganisation do
  @moduledoc """
  Associates the user with the organisation.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts

  @impl true

  def change(%{attributes: %{owner_id: organisation_owner_id}} = changeset, _opts, _context) do
    {:ok, organisation_owner} = Accounts.get_user_by_id(organisation_owner_id, authorize?: false)

    Ash.Changeset.after_action(changeset, fn _changeset, organisation ->
      {:ok, _} =
        Accounts.update_user(organisation_owner, %{current_organisation_id: organisation.id},
          authorize?: false
        )

      {:ok, organisation}
    end)
  end

  def change(changeset, _, _), do: changeset
end
