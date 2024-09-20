defmodule OmedisWeb.LogCategoryLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Log category <%= @log_category.id %>
      <:subtitle>This is a log_category record from your database.</:subtitle>

      <:actions>
        <.link
          patch={~p"/tenants/#{@tenant.slug}/log_categories/#{@log_category}/show/edit"}
          phx-click={JS.push_focus()}
        >
          <.button>Edit log_category</.button>
        </.link>

        <.link
          navigate={~p"/tenants/#{@tenant.slug}/log_categories/#{@log_category}/log_entries"}
          phx-click={JS.push_focus()}
        >
          <.button>View Log entries</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id"><%= @log_category.id %></:item>

      <:item title="Name"><%= @log_category.name %></:item>

      <:item title="Tenant id"><%= @log_category.tenant_id %></:item>
      <:item title="Color code"><%= @log_category.color_code %></:item>
      <:item title="position"><%= @log_category.position %></:item>
    </.list>

    <.back navigate={~p"/tenants/#{@tenant.slug}/log_categories"}>Back to log categories</.back>

    <.modal
      :if={@live_action == :edit}
      id="log_category-modal"
      show
      on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/log_categories/#{@log_category}")}
    >
      <.live_component
        module={OmedisWeb.LogCategoryLive.FormComponent}
        id={@log_category.id}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        tenants={@tenants}
        log_category={@log_category}
        patch={~p"/tenants/#{@tenant.slug}/log_categories/#{@log_category}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id}, _, socket) do
    tenant = Tenant.by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:log_category, LogCategory.by_id!(id))
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, tenant)}
  end

  defp page_title(:show), do: "Show Log category"
  defp page_title(:edit), do: "Edit Log category"
end
