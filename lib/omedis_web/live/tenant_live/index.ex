defmodule OmedisWeb.TenantLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Tenants
      <:actions>
        <.link patch={~p"/tenants/new"}>
          <.button>New Tenant</.button>
        </.link>
      </:actions>
    </.header>

    <div class="overflow-x-auto">
      <.table
        id="tenants"
        rows={@streams.tenants}
        row_click={fn {_id, tenant} -> JS.navigate(~p"/tenants/#{tenant.slug}") end}
      >
        <:col :let={{_id, tenant}} label="Name">
          <%= tenant.name %>
          <%= if tenant.additional_info do %>
            <br /><span class="text-gray-500">(<%= tenant.additional_info %>)</span>
          <% end %>
        </:col>
        <:col :let={{_id, tenant}} label="Street and Po Box">
          <%= tenant.street %>
          <%= if tenant.street2 do %>
            <br /><span class="text-gray-500"><%= tenant.street2 %></span>
          <% end %>
          <%= if tenant.po_box do %>
            <br /><span class="text-gray-500"><%= tenant.po_box %></span>
          <% end %>
        </:col>

        <:col :let={{_id, tenant}} label="Po box"><%= tenant.po_box %></:col>
        <:col :let={{_id, tenant}} label="Zip code"><%= tenant.zip_code %></:col>
        <:col :let={{_id, tenant}} label="City"><%= tenant.city %></:col>
        <:col :let={{_id, tenant}} label="Canton"><%= tenant.canton %></:col>
        <:col :let={{_id, tenant}} label="Country"><%= tenant.country %></:col>
        <:col :let={{_id, tenant}} label="Description"><%= tenant.description %></:col>
        <:col :let={{_id, tenant}} label="Owner"><%= tenant.owner_id %></:col>
        <:col :let={{_id, tenant}} label="Phone"><%= tenant.phone %></:col>
        <:col :let={{_id, tenant}} label="Fax"><%= tenant.fax %></:col>
        <:col :let={{_id, tenant}} label="Email"><%= tenant.email %></:col>
        <:col :let={{_id, tenant}} label="Website"><%= tenant.website %></:col>
        <:col :let={{_id, tenant}} label="Zsr number"><%= tenant.zsr_number %></:col>
        <:col :let={{_id, tenant}} label="Ean gln"><%= tenant.ean_gln %></:col>
        <:col :let={{_id, tenant}} label="Uid bfs number"><%= tenant.uid_bfs_number %></:col>
        <:col :let={{_id, tenant}} label="Trade register no"><%= tenant.trade_register_no %></:col>
        <:col :let={{_id, tenant}} label="Bur number"><%= tenant.bur_number %></:col>
        <:col :let={{_id, tenant}} label="Account number"><%= tenant.account_number %></:col>
        <:col :let={{_id, tenant}} label="Iban"><%= tenant.iban %></:col>
        <:col :let={{_id, tenant}} label="Bic"><%= tenant.bic %></:col>
        <:col :let={{_id, tenant}} label="Bank"><%= tenant.bank %></:col>
        <:col :let={{_id, tenant}} label="Account holder"><%= tenant.account_holder %></:col>
        <:action :let={{_id, tenant}}>
          <div class="sr-only">
            <.link navigate={~p"/tenants/#{tenant.slug}"}>Show</.link>
          </div>
          <.link patch={~p"/tenants/#{tenant.slug}/edit"}>Edit</.link>
        </:action>
      </.table>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="tenant-modal"
      show
      on_cancel={JS.patch(~p"/tenants")}
    >
      <.live_component
        module={OmedisWeb.TenantLive.FormComponent}
        id={(@tenant && @tenant.slug) || :new}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        current_user={@current_user}
        patch={~p"/tenants"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :tenants, Ash.read!(Tenant))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    socket
    |> assign(:page_title, "Edit Tenant")
    |> assign(:tenant, Tenant.by_slug!(slug))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tenant")
    |> assign(:tenant, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tenants")
    |> assign(:tenant, nil)
  end

  @impl true
  def handle_info({OmedisWeb.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply, stream_insert(socket, :tenants, tenant)}
  end
end
