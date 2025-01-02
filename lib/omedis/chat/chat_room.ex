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
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :organisation_id,
        :name
      ]

      primary? true
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
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :organisation_id, :uuid, allow_nil?: true, public?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
