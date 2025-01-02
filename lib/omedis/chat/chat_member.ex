defmodule Omedis.Chats.ChatMember do
  @moduledoc """
  Represents a chat room member in the system.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    notifiers: [Ash.Notifier.PubSub],
    domain: Omedis.Chats

  postgres do
    table "chat_room_members"
    repo Omedis.Repo

    custom_indexes do
      index :chat_room_id
      index :user_id
      index [:chat_room_id, :user_id]
      index :created_at
      index :updated_at
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :chat_room_id,
        :user_id
      ]

      primary? true
    end
  end

  pub_sub do
    module OmedisWeb.Endpoint

    prefix "chat_member"
    publish :create, ["created", :chat_room_id]
    publish :update, ["updated", :id]
  end

  attributes do
    uuid_primary_key :id
    attribute :chat_room_id, :uuid, allow_nil?: false, public?: false
    attribute :user_id, :uuid, allow_nil?: false, public?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :chat_room, Omedis.Chats.ChatRoom
    belongs_to :user, Omedis.Accounts.User
  end
end
