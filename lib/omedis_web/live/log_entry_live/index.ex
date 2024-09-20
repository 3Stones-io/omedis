defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Log entries
      <:actions>
        <.link patch={~p"/log_entries/new"}>
          <.button>New Log entry</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="log_entries"
      rows={@streams.log_entries}
      row_click={fn {_id, log_entry} -> JS.navigate(~p"/log_entries/#{log_entry}") end}
    >
      <:col :let={{_id, log_entry}} label="Id"><%= log_entry.id %></:col>

      <:col :let={{_id, log_entry}} label="Comment"><%= log_entry.comment %></:col>

      <:col :let={{_id, log_entry}} label="Tenant"><%= log_entry.tenant_id %></:col>

      <:col :let={{_id, log_entry}} label="Log category"><%= log_entry.log_category_id %></:col>

      <:col :let={{_id, log_entry}} label="User"><%= log_entry.user_id %></:col>

      <:col :let={{_id, log_entry}} label="Start at"><%= log_entry.start_at %></:col>

      <:col :let={{_id, log_entry}} label="End at"><%= log_entry.end_at %></:col>

      <:action :let={{_id, log_entry}}>
        <div class="sr-only">
          <.link navigate={~p"/log_entries/#{log_entry}"}>Show</.link>
        </div>

        <.link patch={~p"/log_entries/#{log_entry}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, log_entry}}>
        <.link
          phx-click={JS.push("delete", value: %{id: log_entry.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="log_entry-modal"
      show
      on_cancel={JS.patch(~p"/log_entries")}
    >
      <.live_component
        module={OmedisWeb.LogEntryLive.FormComponent}
        id={(@log_entry && @log_entry.id) || :new}
        title={@page_title}
        action={@live_action}
        log_entry={@log_entry}
        patch={~p"/log_entries"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :log_entries, Ash.read!(Omedis.Accounts.LogEntry))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Log entry")
    |> assign(:log_entry, Ash.get!(Omedis.Accounts.LogEntry, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Log entry")
    |> assign(:log_entry, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Log entries")
    |> assign(:log_entry, nil)
  end

  @impl true
  def handle_info({OmedisWeb.LogEntryLive.FormComponent, {:saved, log_entry}}, socket) do
    {:noreply, stream_insert(socket, :log_entries, log_entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    log_entry = Ash.get!(Omedis.Accounts.LogEntry, id)
    Ash.destroy!(log_entry)

    {:noreply, stream_delete(socket, :log_entries, log_entry)}
  end
end
