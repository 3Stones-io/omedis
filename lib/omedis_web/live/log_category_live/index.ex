defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_tenant={@current_tenant}
      language={@language}
      tenants_count={@tenants_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {gettext("Home"), ~p"/", false},
            {gettext("Tenants"), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant}", false},
            {gettext("Groups"), ~p"/tenants/#{@tenant}/groups", false},
            {@group.name, ~p"/tenants/#{@tenant}/groups/#{@group}", false},
            {gettext("Log Categories"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Log categories") %>
          <% end) %>

          <:actions>
            <.link
              :if={Ash.can?({LogCategory, :create}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant}/groups/#{@group}/log_categories/new"}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Log category") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="log-categories"
          rows={@streams.log_categories}
          row_click={
            fn {_id, log_category} ->
              JS.navigate(~p"/tenants/#{@tenant}/groups/#{@group}/log_categories/#{log_category}")
            end
          }
        >
          <:col :let={{_id, log_category}} label={with_locale(@language, fn -> gettext("Name") end)}>
            <.custom_color_button color={log_category.color_code}>
              <%= log_category.name %>
            </.custom_color_button>
          </:col>

          <:col
            :let={{_id, log_category}}
            label={with_locale(@language, fn -> gettext("Position") end)}
          >
            <div
              :if={Ash.can?({log_category, :update}, @current_user, tenant: @tenant)}
              class="position flex items-center"
            >
              <span class="inline-flex flex-col">
                <button
                  type="button"
                  class="position-up"
                  id={"move-up-#{log_category.id}"}
                  phx-click="move-up"
                  phx-value-log-category-id={log_category.id}
                >
                  <.icon name="hero-arrow-up-circle-solid" class="h-5 w-5 arrow" />
                </button>
                <button
                  type="button"
                  class="position-down"
                  id={"move-down-#{log_category.id}"}
                  phx-click="move-down"
                  phx-value-log-category-id={log_category.id}
                >
                  <.icon name="hero-arrow-down-circle-solid" class="h-5 w-5 arrow" />
                </button>
              </span>
            </div>
          </:col>

          <:col :let={{_id, log_category}}>
            <%= if log_category.is_default do %>
              <span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
                <%= with_locale(@language, fn -> gettext("Default") end) %>
              </span>
            <% end %>
          </:col>

          <:action :let={{_id, log_category}}>
            <div class="sr-only">
              <.link navigate={
                ~p"/tenants/#{@tenant}/groups/#{@group}/log_categories/#{log_category}"
              }>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Show") %>
                <% end) %>
              </.link>
            </div>

            <.link
              :if={Ash.can?({log_category, :update}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant}/groups/#{@group}/log_categories/#{log_category}/edit"}
            >
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
          on_cancel={JS.patch(~p"/tenants/#{@tenant}/groups/#{@group}/log_categories")}
        >
          <.live_component
            module={OmedisWeb.LogCategoryLive.FormComponent}
            id={(@log_category && @log_category.id) || :new}
            current_user={@current_user}
            title={@page_title}
            groups={@groups}
            tenant={@tenant}
            projects={@projects}
            group={@group}
            is_custom_color={@is_custom_color}
            language={@language}
            action={@live_action}
            log_category={@log_category}
            patch={~p"/tenants/#{@tenant}/groups/#{@group}/log_categories"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants/#{@tenant}/groups/#{@group}/log_categories"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  def mount(
        %{"slug" => slug, "group_slug" => group_slug},
        %{"language" => language} = _session,
        socket
      ) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Omedis.PubSub, "log_category_positions_updated")

    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)
    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: tenant)

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group, actor: socket.assigns.current_user, tenant: tenant))
     |> assign(
       :projects,
       Project.by_tenant_id!(%{tenant_id: tenant.id},
         actor: socket.assigns.current_user,
         tenant: tenant
       )
     )
     |> assign(:group, group)
     |> assign(:is_custom_color, false)
     |> stream(:log_categories, [])}
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Omedis.PubSub, "log_category_positions_updated")

    {:ok,
     socket
     |> assign(:current_page, 1)
     |> assign(:language, language)
     |> assign(:total_pages, 0)
     |> assign(:tenants, Ash.read!(Tenant, actor: socket.assigns.current_user))
     |> assign(:tenant, nil)
     |> stream(:log_categories, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant
    log_category = LogCategory.by_id!(id, actor: actor, tenant: tenant)

    if Ash.can?({log_category, :update}, actor, tenant: tenant) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Log Category") end)
      )
      |> assign(:log_category, log_category)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/tenants/#{tenant}/groups/#{socket.assigns.group}/log_categories")
    end
  end

  defp apply_action(socket, :new, _params) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant

    if Ash.can?({LogCategory, :create}, actor, tenant: tenant) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("New Log Category") end)
      )
      |> assign(:log_category, nil)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/tenants/#{tenant}/groups/#{socket.assigns.group}/log_categories")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Log categories") end)
    )
    |> assign(:log_category, nil)
    |> assign(:params, params)
    |> list_paginated_log_categories(params)
  end

  defp list_paginated_log_categories(socket, params) do
    PaginationUtils.list_paginated(socket, params, :log_categories, fn offset ->
      LogCategory.list_paginated(
        %{group_id: socket.assigns.group.id},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.tenant
      )
    end)
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end

  @impl true
  def handle_info("updated_positions", socket) do
    {:noreply, list_paginated_log_categories(socket, Map.get(socket.assigns, :params, %{}))}
  end

  @impl true
  def handle_event("move-up", %{"log-category-id" => log_category_id}, socket) do
    case Ash.get(LogCategory, log_category_id,
           actor: socket.assigns.current_user,
           tenant: socket.assigns.tenant
         ) do
      {:ok, log_category} ->
        LogCategory.move_up(log_category,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.tenant
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("move-down", %{"log-category-id" => log_category_id}, socket) do
    case Ash.get(LogCategory, log_category_id,
           actor: socket.assigns.current_user,
           tenant: socket.assigns.tenant
         ) do
      {:ok, log_category} ->
        LogCategory.move_down(log_category,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.tenant
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end
end
