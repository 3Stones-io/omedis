defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.LogEntry
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
          {"Log Categories", ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories",
           false},
          {@log_category.name,
           ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories/#{@log_category.id}",
           false},
          {"Log Entries", "", true}
        ]} />

        <.header>
          Listing Log entries for <%= @log_category.name %>
        </.header>

        <.table id="log_entries" rows={@streams.log_entries}>
          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("Comment") end)}>
            <%= log_entry.comment %>
          </:col>

          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("Start at") end)}>
            <%= log_entry.start_at %>
          </:col>

          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("End at") end)}>
            <%= log_entry.end_at %>
          </:col>
        </.table>
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

  @impl true
  def mount(params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> list_paginated_log_entries(params)}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id} = params, _url, socket) do
    tenant = Tenant.by_slug!(slug)

    {:ok, log_category} =
      id
      |> LogCategory.by_id!()
      |> Ash.load(:group)

    {:noreply,
     socket
     |> assign(:group, log_category.group)
     |> assign(:log_category, log_category)
     |> assign(:tenant, tenant)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Log entries") end))
    |> assign(:log_entry, nil)
  end

  defp list_paginated_log_entries(socket, params, opts \\ [reset_stream: false]) do
    limit = PaginationUtils.maybe_parse_value(:limit, params["limit"])
    page = PaginationUtils.maybe_parse_value(:page, params["page"])

    case list_paginated_log_entries(params) do
      {:ok, %{count: total_count, results: log_entries}} ->
        reset_stream = opts[:reset_stream]
        total_pages = ceil(total_count / limit)

        socket
        |> assign(:current_page, page)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> stream(:log_entries, log_entries, reset: reset_stream)

      {:error, _error} ->
        socket
        |> assign(:current_page, 1)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, 0)
        |> assign(:total_pages, 0)
        |> stream(:tenants, [])
    end
  end

  defp list_paginated_log_entries(params) do
    case params do
      %{"limit" => limit, "page" => offset} when not is_nil(limit) and not is_nil(offset) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        LogEntry.by_log_category(%{log_category_id: params["id"]},
          page: [count: true, limit: limit_value, offset: offset_value]
        )

      %{"limit" => limit} when not is_nil(limit) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)

        LogEntry.by_log_category(%{log_category_id: params["id"]},
          page: [count: true, limit: limit_value]
        )

      %{"page" => offset} when not is_nil(offset) ->
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        LogEntry.by_log_category(%{log_category_id: params["id"]},
          page: [count: true, offset: offset_value]
        )

      _other ->
        LogEntry.by_log_category(%{log_category_id: params["id"]}, page: [count: true])
    end
  end

  @impl true
  def handle_event("change_page", %{"limit" => limit, "page" => page} = params, socket) do
    {:noreply,
     socket
     |> list_paginated_log_entries(params, reset_stream: true)
     |> push_navigate(
       to:
         ~p"/tenants/#{socket.assigns.tenant.slug}/log_categories/#{socket.assigns.log_category.id}/log_entries?page=#{page}&limit=#{limit}"
     )}
  end
end
