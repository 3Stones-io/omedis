defmodule OmedisWeb.LogCategoryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @number_of_records_per_page 10

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
            projects={@projects}
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
    group = Group.by_slug!(group_slug)

    tenant = Tenant.by_slug!(slug)
    next_position = LogCategory.get_max_position_by_group_id(group.id) + 1

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group))
     |> assign(:projects, Project.by_tenant_id!(%{tenant_id: tenant.id}))
     |> assign(:group, group)
     |> assign(:is_custom_color, false)
     |> assign(:next_position, next_position)
     |> stream(:log_categories, [])}
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
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

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Log categories") end)
    )
    |> assign(:log_category, nil)
    |> list_paginated_log_categories(params)
  end

  defp list_paginated_log_categories(socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])

    case list_paginated_log_categories(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        total_pages = max(1, ceil(total_count / @number_of_records_per_page))
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

      _other ->
        LogCategory.list_paginated(page: [count: true])
    end
  end

  @impl true
  def handle_info({OmedisWeb.LogCategoryLive.FormComponent, {:saved, log_category}}, socket) do
    {:noreply, stream_insert(socket, :log_categories, log_category)}
  end
end
