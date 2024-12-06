defmodule Omedis.Accounts.Changes.MaybeCreateOrganisation do
  @moduledoc false

  use Ash.Resource.Change

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.Organisation

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, user ->
      if invitee?(user.email) do
        user
      else
        create_organisation(user)
      end

      {:ok, user}
    end)
  end

  defp invitee?(email) do
    Invitation
    |> Ash.Query.filter(email: email)
    |> Ash.read_one!(authorize?: false)
  end

  defp create_organisation(user) do
    organisation_slug =
      user.email
      |> Ash.CiString.value()
      |> Slug.slugify()

    Organisation.create!(
      %{
        name: user.email,
        slug: organisation_slug,
        owner_id: user.id
      },
      actor: user
    )
  end
end
