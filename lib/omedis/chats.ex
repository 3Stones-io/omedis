defmodule Omedis.Chats do
  @moduledoc """
  Represents the chats domain.
  """
  use Ash.Domain

  require Ash.Query

  resources do
    resource Omedis.Chats.ChatRoom
    resource Omedis.Chats.ChatMember
    resource Omedis.Chats.ChatMessage
    resource Omedis.Chats.ChatMessageView
  end
end
