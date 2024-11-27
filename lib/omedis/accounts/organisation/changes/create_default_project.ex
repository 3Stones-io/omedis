defmodule Omedis.Accounts.Organisation.Changes.CreateDefaultProject do
  @moduledoc """
  Creates a default project called "Organisation" when a new organisation is created.
  """
  use Ash.Resource.Change

  alias Omedis.Accounts.Project

  @impl true
  def change(changeset, _, %{actor: nil}), do: changeset

  def change(changeset, _, context) do
    actor = Map.get(context, :actor)

    Ash.Changeset.after_action(changeset, fn _changeset, organisation ->
      create_default_project(organisation, actor)
      {:ok, organisation}
    end)
  end

  defp create_default_project(organisation, actor) do
    {:ok, _project} =
      Project.create(
        %{
          name: "Organisation",
          position: "1",
          organisation_id: organisation.id
        },
        actor: actor,
        tenant: organisation,
        authorize?: false
      )
  end
end
