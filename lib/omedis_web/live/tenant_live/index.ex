defmodule OmedisWeb.TenantLive.Index do
  use OmedisWeb, :live_view
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
          {"Tenants", ~p"/tenants", true}
        ]} />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Tenants") %>
          <% end) %>
          <:actions>
            <.link patch={~p"/tenants/new"}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Tenant") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <div class="overflow-x-auto">
          <.table
            id="tenants"
            rows={@streams.tenants}
            row_click={fn {_id, tenant} -> JS.navigate(~p"/tenants/#{tenant.slug}") end}
          >
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("Name") end)}>
              <%= tenant.name %>
              <%= if not is_nil(tenant.additional_info) and tenant.additional_info != "" do %>
                <br />
                <%= tenant.additional_info %>
              <% end %>
            </:col>
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("Street") end)}>
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
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("Zip code") end)}>
              <%= tenant.zip_code %>
            </:col>
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("City") end)}>
              <%= tenant.city %>
            </:col>
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("Canton") end)}>
              <%= tenant.canton %>
            </:col>
            <:col :let={{_id, tenant}} label={with_locale(@language, fn -> gettext("Country") end)}>
              <%= tenant.country %>
            </:col>
            <:action :let={{_id, tenant}}>
              <div class="sr-only">
                <.link navigate={~p"/tenants/#{tenant.slug}"}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Show") %>
                  <% end) %>
                </.link>
              </div>
              <.link patch={~p"/tenants/#{tenant.slug}/edit"}>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit") %>
                <% end) %>
              </.link>
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
            language={@language}
            patch={~p"/tenants"}
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

  @impl true
  def mount(params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> list_paginated_tenants(params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Edit Tenant") end))
    |> assign(:tenant, Tenant.by_slug!(slug))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("New Tenant") end))
    |> assign(:tenant, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Tenants") end)
    )
    |> assign(:tenant, nil)
  end

  defp list_paginated_tenants(socket, params, opts \\ [reset_stream: false]) do
    limit = PaginationUtils.maybe_parse_value(:limit, params["limit"])
    page = PaginationUtils.maybe_parse_value(:page, params["page"])

    case list_paginated_tenants(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        reset_stream = opts[:reset_stream]
        total_pages = ceil(total_count / limit)

        socket
        |> assign(:current_page, page)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> stream(:tenants, tenants, reset: reset_stream)

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

  defp list_paginated_tenants(params) do
    case params do
      %{"limit" => limit, "page" => offset} when not is_nil(limit) and not is_nil(offset) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Tenant.list_paginated(page: [count: true, limit: limit_value, offset: offset_value])

      %{"limit" => limit} when not is_nil(limit) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)

        Tenant.list_paginated(page: [count: true, limit: limit_value])

      %{"page" => offset} when not is_nil(offset) ->
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Tenant.list_paginated(page: [count: true, offset: offset_value])

      _other ->
        Tenant.list_paginated(page: [count: true])
    end
  end

  @impl true
  def handle_event("change_page", %{"limit" => limit, "page" => page} = params, socket) do
    {:noreply,
     socket
     |> list_paginated_tenants(params, reset_stream: true)
     |> push_patch(to: ~p"/tenants?page=#{page}&limit=#{limit}")}
  end

  @impl true
  def handle_info({OmedisWeb.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply,
     socket
     |> assign(:tenants_count, socket.assigns.tenants_count + 1)
     |> stream_insert(:tenants, tenant)}
  end
end
