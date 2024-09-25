defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/tenants/#{@tenant.slug}"} class="button ">Back</.link>
    <.header>
      Listing Log categories
      <:actions>
        <.link patch={~p"/tenants/#{@tenant.slug}/log_categories/new"}>
          <.button>New Log category</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="log_categories"
      rows={@streams.log_categories}
      row_click={
        fn {_id, log_category} ->
          JS.navigate(~p"/tenants/#{@tenant.slug}/log_categories/#{log_category}")
        end
      }
    >
      <:col :let={{_id, log_category}} label="Id"><%= log_category.id %></:col>

      <:col :let={{_id, log_category}} label="Name"><%= log_category.name %></:col>

      <:col :let={{_id, log_category}} label="Tenant"><%= log_category.tenant_id %></:col>
      <:col :let={{_id, log_category}} label="Color code"><%= log_category.color_code %></:col>
      <:col :let={{_id, log_category}} label="position"><%= log_category.position %></:col>

      <:action :let={{_id, log_category}}>
        <div class="sr-only">
          <.link navigate={~p"/tenants/#{@tenant.slug}/log_categories/#{log_category}"}>Show</.link>
        </div>

        <.link patch={~p"/tenants/#{@tenant.slug}/log_categories/#{log_category}/edit"}>Edit</.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="log_category-modal"
      show
      on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/log_categories")}
    >
      <.live_component
        module={OmedisWeb.LogCategoryLive.FormComponent}
        id={(@log_category && @log_category.id) || :new}
        title={@page_title}
        tenants={@tenants}
        tenant={@tenant}
        is_custom_color={@is_custom_color}
        next_position={@next_position}
        action={@live_action}
        log_category={@log_category}
        patch={~p"/tenants/#{@tenant.slug}/log_categories"}
      />
    </.modal>
    """
  end

  def mount(%{"slug" => slug}, _session, socket) do
    tenant = Tenant.by_slug!(slug)
    next_position = LogCategory.get_max_position_by_tenant_id(tenant.id) + 1

    {:ok,
     socket
     |> stream(:log_categories, LogCategory.by_tenant_id!(%{tenant_id: tenant.id}))
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, Tenant.by_id!(tenant.id))
     |> assign(:is_custom_color, false)
     |> assign(:next_position, next_position)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:log_categories, Ash.read!(LogCategory))
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tenant = Tenant.by_slug!(params["slug"])
    next_position = LogCategory.get_max_position_by_tenant_id(tenant.id) + 1

    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:next_position, next_position)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Log category")
    |> assign(:log_category, LogCategory.by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Log category")
    |> assign(:log_category, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Log categories")
    |> assign(:log_category, nil)
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end
end
