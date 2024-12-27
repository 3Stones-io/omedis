defmodule OmedisWeb.CalendarComponents do
  @moduledoc false
  use OmedisWeb, :html

  alias OmedisWeb.CoreComponents

  def priority_message(assigns) do
    ~H"""
    <div
      id={@id}
      class="font-openSans text-sm text-[2b2b2b] bg-[#F0EBFE80] rounded-lg border border-[#d2c0fb] border-[0.5px] px-2 priority-message-container"
    >
      <div class="chat-icon w-full h-full mt-3">
        <CoreComponents.icon name="hero-chat-bubble-oval-left-ellipsis" class="font-bold w-5 h-5" />
      </div>

      <div class="flex title mt-3">
        <p class="font-semibold"><%= @message.sender.name %></p>
        <p class="font-semibold">.</p>
        <p class="text-[#acaaaf] pr-[1.25rem]"><%= @message.sent_at %></p>
      </div>
      <p class="message pb-3"><%= @message.body %></p>

      <div class="buttons grid">
        <button class="border-b border-[#cbcbcd]">
          Ok
        </button>

        <button>
          <CoreComponents.icon name="hero-arrow-uturn-left" class="w-5 h-5" />
        </button>
      </div>
    </div>
    """
  end

  def priority_message_stack(assigns) do
    ~H"""
    <div class="priority-message-stack">
      <.priority_message :for={{dom_id, message} <- @messages} id={dom_id} message={message} />
    </div>
    """
  end
end
