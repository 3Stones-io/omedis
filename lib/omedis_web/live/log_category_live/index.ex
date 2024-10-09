defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

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
            <span style={[
              "background: #{log_category.color_code}; display: inline-block; padding: 0.15rem; border-radius: 5px"
            ]}>
              <%= log_category.name %>
            </span>
          </:col>

          <:col :let={{_id, _log_category}} label={with_locale(@language, fn -> gettext("Group") end)}>
            <.link navigate={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}"}>
              <%= @group.slug %>
            </.link>
          </:col>

          <:col
            :let={{_id, log_category}}
            label={with_locale(@language, fn -> gettext("Position") end)}
          >
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
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          limit={@limit}
          page_start={@page_start}
          total_count={@total_count}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  def mount(
        %{"slug" => slug, "group_slug" => group_slug} = params,
        %{"language" => language} = _session,
        socket
      ) do
    group = Group.by_slug!(group_slug)

    tenant = Tenant.by_slug!(slug)
    next_position = LogCategory.get_max_position_by_group_id(group.id) + 1

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group))
     |> assign(:group, group)
     |> assign(:is_custom_color, false)
     |> assign(:next_position, next_position)
     |> list_paginated_log_categories(params)}
  end

  @impl true
  def mount(params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, nil)
     |> list_paginated_log_categories(params)}
  end

  defp list_paginated_log_categories(socket, params, opts \\ [reset_stream: false]) do
    limit = PaginationUtils.maybe_parse_value(:limit, params["limit"])
    page = PaginationUtils.maybe_parse_value(:page, params["page"])

    case list_paginated_log_categories(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        reset_stream = opts[:reset_stream]
        total_pages = ceil(total_count / limit)

        socket
        |> assign(:current_page, page)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> stream(:log_categories, tenants, reset: reset_stream)

      {:error, _error} ->
        socket
        |> assign(:current_page, 1)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, 0)
        |> assign(:total_pages, 0)
        |> stream(:log_categories, [])
    end
  end

  defp list_paginated_log_categories(params) do
    case params do
      %{"limit" => limit, "page" => offset} when not is_nil(limit) and not is_nil(offset) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        LogCategory.list_paginated(page: [count: true, limit: limit_value, offset: offset_value])

      %{"limit" => limit} when not is_nil(limit) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)

        LogCategory.list_paginated(page: [count: true, limit: limit_value])

      %{"page" => offset} when not is_nil(offset) ->
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        LogCategory.list_paginated(page: [count: true, offset: offset_value])

      _other ->
        LogCategory.list_paginated(page: [count: true])
    end
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
  def handle_event("change_page", %{"limit" => limit, "page" => page} = params, socket) do
    {:noreply,
     socket
     |> list_paginated_log_categories(params, reset_stream: true)
     |> push_patch(
       to:
         ~p"/tenants/#{socket.assigns.tenant.slug}/groups/#{socket.assigns.group.slug}/log_categories?page=#{page}&limit=#{limit}"
     )}
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end
end
