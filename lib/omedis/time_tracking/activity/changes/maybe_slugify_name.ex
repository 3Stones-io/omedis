defmodule Omedis.TimeTracking.Activity.Changes.MaybeSlugifyName do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Omedis.Accounts
  alias Omedis.TimeTracking

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, context) do
    Changeset.before_action(changeset, fn changeset ->
      slugify_name(changeset, context.actor, context.tenant)
    end)
  end

  defp slugify_name(changeset, actor, organisation) do
    case Changeset.get_attribute(changeset, :name) do
      name when is_binary(name) ->
        Changeset.force_change_attribute(
          changeset,
          :slug,
          maybe_slugify_name(Slug.slugify(name), actor, organisation)
        )

      _ ->
        changeset
    end
  end

  defp maybe_slugify_name(slug, actor, organisation) do
    if Accounts.slug_exists?(
         TimeTracking.Activity,
         [slug: slug, organisation_id: organisation.id],
         actor: actor,
         tenant: organisation,
         authorize?: false
       ) do
      new_slug = "#{slug}#{:rand.uniform(99)}"
      maybe_slugify_name(new_slug, actor, organisation)
    else
      slug
    end
  end
end
