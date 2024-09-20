defmodule OmedisWeb.LogEntryLive.Show do
  use OmedisWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Log entry <%= @log_entry.id %>
      <:subtitle>This is a log_entry record from your database.</:subtitle>

      <:actions>
        <.link patch={~p"/log_entries/#{@log_entry}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit log_entry</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id"><%= @log_entry.id %></:item>

      <:item title="Comment"><%= @log_entry.comment %></:item>

      <:item title="Tenant"><%= @log_entry.tenant_id %></:item>

      <:item title="Log category"><%= @log_entry.log_category_id %></:item>

      <:item title="User"><%= @log_entry.user_id %></:item>

      <:item title="Start at"><%= @log_entry.start_at %></:item>

      <:item title="End at"><%= @log_entry.end_at %></:item>
    </.list>

    <.back navigate={~p"/log_entries"}>Back to log_entries</.back>

    <.modal
      :if={@live_action == :edit}
      id="log_entry-modal"
      show
      on_cancel={JS.patch(~p"/log_entries/#{@log_entry}")}
    >
      <.live_component
        module={OmedisWeb.LogEntryLive.FormComponent}
        id={@log_entry.id}
        title={@page_title}
        action={@live_action}
        log_entry={@log_entry}
        patch={~p"/log_entries/#{@log_entry}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:log_entry, Ash.get!(Omedis.Accounts.LogEntry, id))}
  end

  defp page_title(:show), do: "Show Log entry"
  defp page_title(:edit), do: "Edit Log entry"
end
