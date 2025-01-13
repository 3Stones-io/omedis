defmodule Omedis.Accounts.Organisation.Changes.MaybeSlugifyName do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Omedis.Accounts

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, context) do
    Changeset.before_action(changeset, fn changeset ->
      slugify_name(changeset, context.actor)
    end)
  end

  defp slugify_name(changeset, actor) do
    case Changeset.get_attribute(changeset, :name) do
      name when is_binary(name) ->
        Changeset.force_change_attribute(
          changeset,
          :slug,
          maybe_slugify_name(Slug.slugify(name), actor)
        )

      _ ->
        changeset
    end
  end

  defp maybe_slugify_name(slug, actor) do
    if Accounts.slug_exists?(
         Accounts.Organisation,
         [slug: slug],
         actor: actor,
         authorize?: false
       ) do
      new_slug = "#{slug}#{:rand.uniform(99)}"
      maybe_slugify_name(new_slug, actor)
    else
      slug
    end
  end
end
