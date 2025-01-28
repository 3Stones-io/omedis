defmodule OmedisWeb.PlaygroundLive do
  use OmedisWeb, :live_view

  alias OmedisWeb.ClientDoctorFormComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <section>
      <ClientDoctorFormComponents.navbar breadcrumb_items={[
        {"Client", ~p"/", false},
        {"Create new client", ~p"/", true}
      ]} />
      <section class="min-h-full content">
        <h1>Create a new client</h1>
      </section>
    </section>
    """
  end
end
