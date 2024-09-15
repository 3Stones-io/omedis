defmodule Omedis.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    domain: Omedis.Accounts

  postgres do
    table "tokens"
    repo Omedis.Repo
  end
end
