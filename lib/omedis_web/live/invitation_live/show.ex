defmodule OmedisWeb.InvitationLive.Show do
  use OmedisWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Add user registration form
  def apply_action(socket, :show, %{"id" => _id}) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Invitation</h1>
    </div>
    """
  end
end
