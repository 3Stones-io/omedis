defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.LogEntry
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Log entries for <%= @log_category.name %>
    </.header>

    <.table id="log_entries" rows={@streams.log_entries}>
      <:col :let={{_id, log_entry}} label="Id"><%= log_entry.id %></:col>

      <:col :let={{_id, log_entry}} label="Comment"><%= log_entry.comment %></:col>

      <:col :let={{_id, log_entry}} label="Tenant"><%= log_entry.tenant_id %></:col>

      <:col :let={{_id, log_entry}} label="Log category"><%= log_entry.log_category_id %></:col>

      <:col :let={{_id, log_entry}} label="User"><%= log_entry.user_id %></:col>

      <:col :let={{_id, log_entry}} label="Start at"><%= log_entry.start_at %></:col>

      <:col :let={{_id, log_entry}} label="End at"><%= log_entry.end_at %></:col>
    </.table>
    """
  end

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    case LogEntry.by_log_category(%{log_category_id: id}) do
      {:ok, log_entries} ->
        {:ok, stream(socket, :log_entries, log_entries)}

      _ ->
        {:ok, stream(socket, :log_entries, [])}
    end
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id} = params, _url, socket) do
    tenant = Tenant.by_slug!(slug)

    log_category = LogCategory.by_id!(id)

    {:noreply,
     socket
     |> assign(:log_category, log_category)
     |> assign(:tenant, tenant)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Log entries")
    |> assign(:log_entry, nil)
  end
end
