defmodule OmedisWeb.PlaygroundLive do
  use OmedisWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Playground</h1>
    </div>
    """
  end
end
