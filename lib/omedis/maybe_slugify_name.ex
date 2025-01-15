defmodule Omedis.MaybeSlugifyName do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Omedis.Accounts

  def change(changeset, _options, context) do
    Changeset.before_action(changeset, fn changeset ->
      slugify_name(changeset, context.actor, context.tenant)
    end)
  end

  defp slugify_name(changeset, actor, tenant) do
    case Changeset.get_attribute(changeset, :name) do
      name when is_binary(name) ->
        Changeset.force_change_attribute(
          changeset,
          :slug,
          maybe_slugify_name(Slug.slugify(name), actor, tenant, changeset.resource)
        )

      _ ->
        changeset
    end
  end

  defp maybe_slugify_name(slug, actor, tenant, resource) do
    conditions = build_slug_conditions(slug, tenant)

    if Accounts.slug_exists?(
         resource,
         conditions,
         actor: actor,
         tenant: tenant,
         authorize?: false
       ) do
      new_slug = "#{slug}#{:rand.uniform(99)}"
      maybe_slugify_name(new_slug, actor, tenant, resource)
    else
      slug
    end
  end

  defp build_slug_conditions(slug, nil), do: [slug: slug]
  defp build_slug_conditions(slug, tenant), do: [slug: slug, organisation_id: tenant.id]
end
