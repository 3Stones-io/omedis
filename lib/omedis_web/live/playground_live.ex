defmodule OmedisWeb.PlaygroundLive do
  use OmedisWeb, :live_view

  alias OmedisWeb.CalendarComponents

  def mount(_params, _session, socket) do
    messages = [
      %{
        id: 1,
        sender: %{name: "Denis Gojak"},
        sent_at: "10:00",
        body: "Hello Heidi, there's a schedule update for you, please call me."
      },
      %{
        id: 2,
        sender: %{name: "Denis Gojak"},
        sent_at: "10:00",
        body: "Hello Heidi, there's a schedule update for you, please call me."
      },
      %{
        id: 3,
        sender: %{name: "Denis Gojak"},
        sent_at: "10:00",
        body: "Hello Heidi, there's a schedule update for you, please call me."
      },
      %{
        id: 4,
        sender: %{name: "Denis Gojak"},
        sent_at: "10:00",
        body: "Hello Heidi, there's a schedule update for you, please call me."
      }
    ]

    {:ok,
     socket
     |> stream(:messages, messages)
     |> assign(:message, List.first(messages))}
  end

  def render(assigns) do
    ~H"""
    <section class="p-4">
      <div id="messages" phx-update="stream" class="mb-3">
        <CalendarComponents.priority_message_stack messages={@streams.messages} />
      </div>

      <div class="playground-message">
        <CalendarComponents.priority_message message={@message} id="message1" />
      </div>
    </section>
    """
  end
end
