defmodule Omedis.Chats.ChatMessage do
  @moduledoc """
  Represents a chat message in the system.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    notifiers: [Ash.Notifier.PubSub],
    domain: Omedis.Chats

  postgres do
    table "chat_messages"
    repo Omedis.Repo

    custom_indexes do
      index :chat_room_id
      index :user_id
      index :reply_to_message_id
      index [:chat_room_id, :user_id]
      index [:chat_room_id, :reply_to_message_id]
      index :created_at
      index :updated_at
    end
  end

  actions do
    defaults [:read, :update]

    create :create do
      accept [
        :chat_room_id,
        :user_id,
        :message
      ]

      primary? true
    end

    destroy :soft_delete do
      argument :destroyed_at, :utc_datetime_usec, default: &DateTime.utc_now/0
      change set_attribute(:deleted_at, arg(:destroyed_at))

      primary? true
    end
  end

  pub_sub do
    module OmedisWeb.Endpoint

    prefix "chat_message"
    publish :create, ["created", :chat_room_id]
    publish :update, ["updated", :id]
    publish :destroy, ["destroyed", :id]
  end

  attributes do
    uuid_primary_key :id
    attribute :message, :string, allow_nil?: false, public?: true
    attribute :is_priority, :boolean, allow_nil?: false, public?: true
    attribute :chat_room_id, :uuid, allow_nil?: false, public?: false
    attribute :user_id, :uuid, allow_nil?: false, public?: false
    attribute :reply_to_message_id, :uuid, allow_nil?: false, public?: false
    attribute :deleted_at, :utc_datetime_usec, allow_nil?: true, public?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :replies, Omedis.Chats.ChatMessage do
      source_attribute :reply_to_message_id
      destination_attribute :id
    end

    belongs_to :user, Omedis.Accounts.User
    belongs_to :chat_room, Omedis.Chats.ChatRoom

    has_many :chat_message_views, Omedis.Chats.ChatMessageView do
      source_attribute :id
      destination_attribute :chat_message_id
    end
  end
end
