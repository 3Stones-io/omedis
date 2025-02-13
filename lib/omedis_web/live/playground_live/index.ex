defmodule OmedisWeb.PlaygroundLive.Index do
  use OmedisWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="py-4">
      <h1 class="text-2xl w-full max-w-md mx-auto font-bold">Omedis Playground Pages</h1>

      <ul class="min-h-[90svh] grid gap-y-4 items-center justify-center">
        <li>
          <.link
            navigate={~p"/playground/client-doctor-forms"}
            class="text-lg text-blue-500 hover:text-blue-700 hover:underline"
          >
            Client Doctor Forms
          </.link>
        </li>

        <li>
          <.link
            navigate={~p"/playground/time-tracking"}
            class="text-lg text-blue-500 hover:text-blue-700 hover:underline"
          >
            Time Tracking
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
