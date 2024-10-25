defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.LogEntry
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
          {"Home", ~p"/tenants/#{@tenant.slug}", false},
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
          resource_path={~p"/tenants/#{@tenant.slug}/log_categories/#{@log_category.id}/log_entries"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> stream(:log_entries, [])}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id} = params, _url, socket) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

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

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Log entries") end))
    |> assign(:log_entry, nil)
    |> list_paginated_log_entries(params)
  end

  defp list_paginated_log_entries(socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])

    case list_paginated_log_entries(params) do
      {:ok, %{count: total_count, results: log_entries}} ->
        total_pages = max(1, ceil(total_count / socket.assigns.number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:log_entries, log_entries, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_paginated_log_entries(params) do
    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        LogEntry.by_log_category(%{log_category_id: params["id"]},
          page: [count: true, offset: offset_value]
        )

      _ ->
        LogEntry.by_log_category(%{log_category_id: params["id"]}, page: [count: true])
    end
  end
end
