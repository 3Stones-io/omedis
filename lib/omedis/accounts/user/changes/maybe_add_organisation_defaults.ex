defmodule Omedis.Accounts.User.Changes.MaybeAddOrganisationDefaults do
  @moduledoc false
  use Ash.Resource.Change

  alias Omedis.Accounts.Organisation

  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &maybe_add_organisation_defaults_to_changeset/1)
  end

  defp maybe_add_organisation_defaults_to_changeset(changeset) do
    organisation_id = Ash.Changeset.get_attribute(changeset, :current_organisation_id)

    if organisation_id do
      organisation = Organisation.by_id!(organisation_id, authorize?: false)

      changeset_attributes =
        changeset.attributes
        |> Map.drop([:id, :created_at, :updated_at, :current_organisation_id])
        |> Map.merge(
          %{
            daily_start_at: organisation.default_daily_start_at,
            daily_end_at: organisation.default_daily_end_at
          },
          fn _key, v1, _v2 -> v1 end
        )

      Ash.Changeset.change_attributes(changeset, changeset_attributes)
    else
      changeset
    end
  end
end
