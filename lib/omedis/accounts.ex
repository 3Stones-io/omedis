defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  alias Omedis.Accounts.Project

  require Ash.Query

  resources do
    resource Omedis.Accounts.Organisation
    resource Omedis.Accounts.Project
    resource Omedis.Accounts.Token
    resource Omedis.Accounts.User
  end

  def get_max_position_by_organisation_id(organisation_id, opts \\ []) do
    Project
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

  def slug_exists?(resource, filters, opts \\ []) do
    resource
    |> Ash.Query.filter(^filters)
    |> Ash.read_one!(opts)
  end
end
