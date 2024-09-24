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
          <%= if not is_nil(tenant.additional_info) and tenant.additional_info != "" do %>
            <br />
            <%= tenant.additional_info %>
          <% end %>
        </:col>
        <:col :let={{_id, tenant}} label="Street">
          <%= tenant.street %>
          <%= if not is_nil(tenant.street2) do %>
            <br />
            <%= tenant.street2 %>
          <% end %>

          <%= if not is_nil(tenant.po_box) do %>
            <br />
            <%= tenant.po_box %>
          <% end %>
        </:col>
        <:col :let={{_id, tenant}} label="Zip code"><%= tenant.zip_code %></:col>
        <:col :let={{_id, tenant}} label="City"><%= tenant.city %></:col>
        <:col :let={{_id, tenant}} label="Canton"><%= tenant.canton %></:col>
        <:col :let={{_id, tenant}} label="Website"><%= tenant.website %></:col>
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
