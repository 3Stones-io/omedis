defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Log categories
      <:actions>
        <.link patch={~p"/log_categories/new"}>
        <.button>New Log category</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="log_categories"
      rows={@streams.log_categories}
      row_click={fn {_id, log_category} -> JS.navigate(~p"/log_categories/#{log_category}") end}
    >
      
        <:col :let={{_id, log_category}} label="Id"><%= log_category.id %></:col>
      
        <:col :let={{_id, log_category}} label="Name"><%= log_category.name %></:col>
      
        <:col :let={{_id, log_category}} label="Tenant"><%= log_category.tenant_id %></:col>
      
      <:action :let={{_id, log_category}}>
        <div class="sr-only">
          <.link navigate={~p"/log_categories/#{log_category}"}>Show</.link>
        </div>
        
          <.link patch={~p"/log_categories/#{log_category}/edit"}>Edit</.link>
        
      </:action>
      
    </.table>


        <.modal :if={@live_action in [:new, :edit]} id="log_category-modal" show on_cancel={JS.patch(~p"/log_categories")}>
          <.live_component
            module={OmedisWeb.LogCategoryLive.FormComponent}
            id={(@log_category && @log_category.id) || :new}
            title={@page_title}
            
            action={@live_action}
            log_category={@log_category}
            patch={~p"/log_categories"}
          />
        </.modal>
      
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :log_categories, Ash.read!(Omedis.Accounts.LogCategory))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Log category")
    |> assign(:log_category, Omedis.Accounts.LogCategory.by_id!(id))
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
