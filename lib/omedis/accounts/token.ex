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
  end

  actions do
    defaults [:read]
  end
end
