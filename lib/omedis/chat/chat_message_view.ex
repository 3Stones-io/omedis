defmodule Omedis.Chats.ChatMessageView do
  @moduledoc """
  Represents a chat message view in the system.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    notifiers: [Ash.Notifier.PubSub],
    domain: Omedis.Chats

  postgres do
    table "chat_messages_views"
    repo Omedis.Repo

    custom_indexes do
      index :chat_message_id
      index :user_id
      index [:chat_message_id, :user_id]
      index :created_at
      index :updated_at
      index :viewed_at
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :chat_message_id,
        :user_id,
        :viewed_at
      ]

      primary? true
    end
  end

  pub_sub do
    module OmedisWeb.Endpoint

    prefix "chat_message_view"
    publish :create, ["created", :chat_message_id]
    publish :update, ["updated", :id]
  end

  attributes do
    uuid_primary_key :id
    attribute :chat_message_id, :uuid, allow_nil?: false, public?: false
    attribute :user_id, :uuid, allow_nil?: false, public?: false
    attribute :viewed_at, :datetime, allow_nil?: false, public?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Omedis.Accounts.User
    belongs_to :chat_message, Omedis.Chats.ChatMessage
  end
end
