defmodule Omedis.Chats.ChatRoom do
  @moduledoc """
  Represents a chat room in the system.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshArchival.Resource],
    notifiers: [Ash.Notifier.PubSub],
    domain: Omedis.Chats

  postgres do
    table "chat_rooms"
    repo Omedis.Repo

    custom_indexes do
      index :organisation_id
      index :created_at
      index :updated_at
      index :user_id
      index [:organisation_id, :user_id]
    end
  end

  code_interface do
    domain Omedis.Chats
    define :read
    define :create
    define :update
    define :destroy
    define :by_id, get_by: [:id], action: :read
    define :by_organisation_id, get_by: [:organisation_id], action: :read
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :organisation_id,
        :name,
        :user_id
      ]

      primary? true
    end

    update :update do
      accept [
        :name
      ]

      primary? true
    end
  end

  policies do
    policy do
      authorize_if always()
    end
  end

  pub_sub do
    module OmedisWeb.Endpoint

    prefix "chat_room"
    publish :create, ["created", :organisation_id]
    publish :update, ["updated", :id]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :organisation_id, :uuid, allow_nil?: true, public?: false
    attribute :user_id, :uuid, allow_nil?: true, public?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organisation, Omedis.Accounts.Organisation
    belongs_to :user, Omedis.Accounts.User

    has_many :members, Omedis.Chats.ChatMember do
      source_attribute :id
      destination_attribute :chat_room_id
    end

    has_many :messages, Omedis.Chats.ChatMessage do
      source_attribute :id
      destination_attribute :chat_room_id
    end
  end
end
