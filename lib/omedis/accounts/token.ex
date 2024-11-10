defmodule Omedis.Accounts.Token do
  @moduledoc """
  Represents tokens used for authentication in the system.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    domain: Omedis.Accounts

  postgres do
    table "tokens"
    repo Omedis.Repo

    references do
      reference :organisation, on_delete: :delete
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
  end

  relationships do
    belongs_to :organisation, Omedis.Accounts.Organisation
  end
end
