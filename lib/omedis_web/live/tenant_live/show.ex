defmodule OmedisWeb.TenantLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Tenant <%= @tenant.id %>
      <:subtitle>This is a tenant record from your database.</:subtitle>

      <:actions>
        <.link patch={~p"/tenants/#{@tenant}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit tenant</.button>
        </.link>
        <.link patch={~p"/tenants/#{@tenant.id}/log_categories"} phx-click={JS.push_focus()}>
          <.button>Log categories</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Id"><%= @tenant.id %></:item>

      <:item title="Name"><%= @tenant.name %></:item>

      <:item title="Additional info"><%= @tenant.additional_info %></:item>

      <:item title="Street"><%= @tenant.street %></:item>

      <:item title="Street2"><%= @tenant.street2 %></:item>

      <:item title="Po box"><%= @tenant.po_box %></:item>

      <:item title="Zip code"><%= @tenant.zip_code %></:item>

      <:item title="City"><%= @tenant.city %></:item>

      <:item title="Canton"><%= @tenant.canton %></:item>

      <:item title="Country"><%= @tenant.country %></:item>

      <:item title="Description"><%= @tenant.description %></:item>

      <:item title="Owner"><%= @tenant.owner_id %></:item>

      <:item title="Phone"><%= @tenant.phone %></:item>

      <:item title="Fax"><%= @tenant.fax %></:item>

      <:item title="Email"><%= @tenant.email %></:item>

      <:item title="Website"><%= @tenant.website %></:item>

      <:item title="Zsr number"><%= @tenant.zsr_number %></:item>

      <:item title="Ean gln"><%= @tenant.ean_gln %></:item>

      <:item title="Uid bfs number"><%= @tenant.uid_bfs_number %></:item>

      <:item title="Trade register no"><%= @tenant.trade_register_no %></:item>

      <:item title="Bur number"><%= @tenant.bur_number %></:item>

      <:item title="Account number"><%= @tenant.account_number %></:item>

      <:item title="Iban"><%= @tenant.iban %></:item>

      <:item title="Bic"><%= @tenant.bic %></:item>

      <:item title="Bank"><%= @tenant.bank %></:item>

      <:item title="Account holder"><%= @tenant.account_holder %></:item>
    </.list>

    <.back navigate={~p"/tenants"}>Back to tenants</.back>

    <.modal
      :if={@live_action == :edit}
      id="tenant-modal"
      show
      on_cancel={JS.patch(~p"/tenants/#{@tenant}")}
    >
      <.live_component
        module={OmedisWeb.TenantLive.FormComponent}
        id={@tenant.id}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        patch={~p"/tenants/#{@tenant}"}
      />
    </.modal>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="log_category-modal"
      show
      on_cancel={JS.patch(~p"/tenant/#{@tenant.id}/log_categories")}
    >
      <.live_component
        module={OmedisWeb.LogCategoryLive.FormComponent}
        id={(@log_category && @log_category.id) || :new}
        title={@page_title}
        tenants={@tenants}
        action={@live_action}
        log_category={@log_category}
        patch={~p"/tenants/#{@tenant.id}/log_categories"}
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
     |> assign(:tenant, Tenant.by_id!(id))}
  end

  defp page_title(:show), do: "Show Tenant"
  defp page_title(:edit), do: "Edit Tenant"
end
