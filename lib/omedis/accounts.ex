defmodule Omedis.Accounts do
  @moduledoc """
  Represents the accounts domain.
  """
  use Ash.Domain

  require Ash.Query

  resources do
    resource Omedis.Accounts.Organisation do
      define :create_organisation, action: :create
      define :get_organisation_by_id, get_by: [:id], action: :read
      define :get_organisation_by_slug, get_by: [:slug], action: :read
      define :list_paginated_organisations, action: :list_paginated
      define :update_organisation, action: :update
    end

    resource Omedis.Accounts.User do
      define :create_user, action: :create
      define :delete_account, action: :destroy
      define :get_user_by_email, get_by: [:email], action: :read
      define :get_user_by_id, get_by: [:id], action: :read
      define :update_user, action: :update
    end

    resource Omedis.Accounts.Token
  end

  def slug_exists?(resource, filters, opts \\ []) do
    resource
    |> Ash.Query.filter(^filters)
    |> Ash.read_one!(opts)
  end
end
