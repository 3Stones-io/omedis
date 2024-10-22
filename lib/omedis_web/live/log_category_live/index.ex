defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

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
        <.breadcrumb items={[
          {"Home", ~p"/", false},
          {"Tenants", ~p"/tenants", false},
          {@tenant.name, ~p"/tenants/#{@tenant.slug}", false},
          {"Groups", ~p"/tenants/#{@tenant.slug}/groups", false},
          {@group.name, ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}", false},
          {"Log Categories", "", true}
        ]} />

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
          id="log-categories"
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
            <span style={[
              "background: #{log_category.color_code}; display: inline-block; padding: 0.15rem; border-radius: 5px"
            ]}>
              <%= log_category.name %>
            </span>
          </:col>

          <:col
            :let={{_id, log_category}}
            label={with_locale(@language, fn -> gettext("Position") end)}
          >
            <p class="position flex items-center">
              <span class="inline-flex flex-col">
                <button
                  type="button"
                  class="position-up"
                  phx-click={
                    JS.push(
                      "move-up",
                      value: %{
                        "log_category_id" => log_category.id
                      }
                    )
                  }
                >
                  <.icon name="hero-arrow-up-circle-solid" class="h-5 w-5 arrow" />
                </button>
                <button
                  type="button"
                  class="position-down"
                  phx-click={
                    JS.push(
                      "move-down",
                      value: %{
                        "log_category_id" => log_category.id
                      }
                    )
                  }
                >
                  <.icon name="hero-arrow-down-circle-solid" class="h-5 w-5 arrow" />
                </button>
              </span>
            </p>
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
            projects={@projects}
            group={@group}
            is_custom_color={@is_custom_color}
            language={@language}
            action={@live_action}
            log_category={@log_category}
            patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories"}
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

    tenant = Tenant.by_slug!(slug)

    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: tenant)

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group))
     |> assign(:projects, Project.by_tenant_id!(%{tenant_id: tenant.id}))
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
     |> assign(:tenants, Ash.read!(Tenant))
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
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])

    case list_paginated_log_categories(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        total_pages = max(1, ceil(total_count / socket.assigns.number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:log_categories, tenants, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_paginated_log_categories(params) do
    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        LogCategory.list_paginated(page: [count: true, offset: offset_value])

      _ ->
        LogCategory.list_paginated(page: [count: true])
    end
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end

  @impl true
  def handle_info("updated_positions", socket) do
    {:noreply, list_paginated_log_categories(socket, socket.assigns.params)}
  end

  @impl true
  def handle_event("move-up", params, socket) do
    %{"log_category_id" => log_category_id} = params

    case Ash.get(LogCategory, log_category_id) do
      {:ok, log_category} ->
        LogCategory.move_up(log_category)

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("move-down", params, socket) do
    %{"log_category_id" => log_category_id} = params

    case Ash.get(LogCategory, log_category_id) do
      {:ok, log_category} ->
        LogCategory.move_down(log_category)

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end
end
