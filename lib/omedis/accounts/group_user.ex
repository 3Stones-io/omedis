defmodule Omedis.Accounts.GroupUser do
  @moduledoc """
  Represents a user in a group.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Omedis.Accounts

  alias Omedis.Accounts.Group
  alias Omedis.Accounts.User

  postgres do
    table "group_users"
    repo Omedis.Repo
  end

  relationships do
    belongs_to :group, Group, primary_key?: true, allow_nil?: false
    belongs_to :user, User, primary_key?: true, allow_nil?: false
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :group_id,
        :user_id
      ]

      primary? true
    end
  end
end
