defmodule Omedis.Projects do
  @moduledoc false

  use Ash.Domain

  require Ash.Query

  resources do
    resource Omedis.Projects.Project do
      define :by_id, get_by: [:id], action: :read
      define :by_organisation_id
      define :latest_by_organisation_id
      define :list_paginated
    end
  end

  def get_max_position_by_organisation_id(organisation_id, opts \\ []) do
    Omedis.Projects.Project
    |> Ash.Query.filter(organisation_id: organisation_id)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.Query.select([:position])
    |> Ash.read!(opts)
    |> Enum.at(0)
    |> case do
      nil -> 0
      record -> record.position |> String.to_integer()
    end
  end
end
