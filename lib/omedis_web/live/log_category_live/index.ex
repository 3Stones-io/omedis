defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}"} class="button ">Back</.link>
    <.header>
      <%= with_locale(@language, fn -> %>
        <%= gettext("Listing Log categories") %>
      <% end) %>

      <:actions>
        <.link patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories/new"}>
          <.button>
            <%= with_locale(@language, fn -> %>
              <%= gettext("New Log category") %>
            <% end) %>
          </.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="log_categories"
      rows={@streams.log_categories}
      row_click={
        fn {_id, log_category} ->
          JS.navigate(
            ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories/#{log_category}"
          )
        end
      }
    >
      <:col :let={{_id, log_category}} label={with_locale(@language, fn -> gettext("Name") end)}>
        <%= log_category.name %> ><%= log_category.name %>
      </:col>

      <:col :let={{_id, log_category}} label={with_locale(@language, fn -> gettext("Group") end)}>
        <%= log_category.group_id %>
      </:col>
      <:col :let={{_id, log_category}} label={with_locale(@language, fn -> gettext("Color code") end)}>
        <%= log_category.color_code %>
      </:col>
      <:col :let={{_id, log_category}} label={with_locale(@language, fn -> gettext("Position") end)}>
        <%= log_category.position %>
      </:col>

      <:action :let={{_id, log_category}}>
        <div class="sr-only">
          <.link navigate={
            ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories/#{log_category}"
          }>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Show") %>
            <% end) %>
          </.link>
        </div>

        <.link patch={
          ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories/#{log_category}/edit"
        }>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Edit") %>
          <% end) %>
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="log_category-modal"
      show
      on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories")}
    >
      <.live_component
        module={OmedisWeb.LogCategoryLive.FormComponent}
        id={(@log_category && @log_category.id) || :new}
        title={@page_title}
        groups={@groups}
        tenant={@tenant}
        group={@group}
        is_custom_color={@is_custom_color}
        next_position={@next_position}
        language={@language}
        action={@live_action}
        log_category={@log_category}
        patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories"}
      />
    </.modal>
    """
  end

  def mount(
        %{"slug" => slug, "group_slug" => group_slug},
        %{"language" => language} = _session,
        socket
      ) do
    group = Group.by_slug!(group_slug)

    tenant = Tenant.by_slug!(slug)
    next_position = LogCategory.get_max_position_by_group_id(group.id) + 1

    {:ok,
     socket
     |> stream(:log_categories, LogCategory.by_group_id!(%{group_id: group.id}))
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group))
     |> assign(:group, group)
     |> assign(:is_custom_color, false)
     |> assign(:next_position, next_position)}
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> stream(:log_categories, Ash.read!(LogCategory))
     |> assign(:language, language)
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    group = Group.by_slug!(params["group_slug"])
    next_position = LogCategory.get_max_position_by_group_id(group.id) + 1

    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:next_position, next_position)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Edit Log category") end)
    )
    |> assign(:log_category, LogCategory.by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("New Log category") end)
    )
    |> assign(:log_category, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Log categories") end)
    )
    |> assign(:log_category, nil)
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end
end
