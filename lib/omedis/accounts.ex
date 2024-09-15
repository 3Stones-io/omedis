defmodule Omedis.Accounts do
  use Ash.Domain

  resources do
    resource Omedis.Accounts.User
    resource Omedis.Accounts.Token
  end
end
