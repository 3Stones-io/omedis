defmodule OmedisWeb.GroupLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
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
          {"Groups", ~p"/tenants/#{@tenant.slug}", true}
        ]} />

        <div>
          <.link navigate={~p"/tenants/#{@tenant.slug}"} class="button">Back</.link>
        </div>
        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Groups") %>
          <% end) %>
          <:actions>
            <.link patch={~p"/tenants/#{@tenant.slug}/groups/new"}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Group") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="groups"
          rows={@streams.groups}
          row_click={
            fn {_id, group} -> JS.navigate(~p"/tenants/#{@tenant.slug}/groups/#{group.slug}") end
          }
        >
          <:col :let={{_id, group}} label={with_locale(@language, fn -> gettext("Name") end)}>
            <%= group.name %>
          </:col>

          <:col :let={{_id, group}} label={with_locale(@language, fn -> gettext("Slug") end)}>
            <%= group.slug %>
          </:col>

          <:col :let={{_id, group}} label={with_locale(@language, fn -> gettext("Actions") end)}>
            <div class="flex gap-4">
              <.link
                patch={~p"/tenants/#{@tenant.slug}/groups/#{group.slug}/edit"}
                class="font-semibold"
              >
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit") %>
                <% end) %>
              </.link>
              <.link>
                <p class="font-semibold" phx-click="delete" phx-value-id={group.id}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Delete") %>
                  <% end) %>
                </p>
              </.link>
            </div>
          </:col>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="group-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/groups")}
        >
          <.live_component
            module={OmedisWeb.GroupLive.FormComponent}
            id={(@group && @group.slug) || :new}
            title={@page_title}
            action={@live_action}
            language={@language}
            group={@group}
            current_user={@current_user}
            tenant={@tenant}
            patch={~p"/tenants/#{@tenant.slug}/groups"}
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
  def mount(%{"slug" => slug} = params, %{"language" => language} = _session, socket) do
    tenant = Tenant.by_slug!(slug)
    # groups = Group.by_tenant_id!(%{tenant_id: tenant.id})

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:language, language)
     |> list_paginated_groups(params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"group_slug" => group_slug}) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Edit Group") end))
    |> assign(:group, Group.by_slug!(group_slug))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("New Group") end))
    |> assign(:group, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Groups") end)
    )
    |> assign(:group, nil)
  end

  defp list_paginated_groups(socket, params, opts \\ [reset_stream: false]) do
    limit = PaginationUtils.maybe_parse_value(:limit, params["limit"])
    page = PaginationUtils.maybe_parse_value(:page, params["page"])

    case list_paginated_groups_by_tenant_id(socket.assigns.tenant.id, params) do
      {:ok, %{count: total_count, results: groups}} ->
        reset_stream = opts[:reset_stream]
        total_pages = ceil(total_count / limit)

        socket
        |> assign(:current_page, page)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> stream(:groups, groups, reset: reset_stream)

      {:error, _error} ->
        socket
        |> assign(:current_page, 1)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, 0)
        |> assign(:total_pages, 0)
        |> stream(:groups, [])
    end
  end

  defp list_paginated_groups_by_tenant_id(tenant_id, params) do
    case params do
      %{"limit" => limit, "page" => offset} when not is_nil(limit) and not is_nil(offset) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Group.by_tenant_id(%{tenant_id: tenant_id},
          page: [count: true, limit: limit_value, offset: offset_value]
        )

      %{"limit" => limit} when not is_nil(limit) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)

        Group.by_tenant_id(%{tenant_id: tenant_id}, page: [count: true, limit: limit_value])

      %{"page" => offset} when not is_nil(offset) ->
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Group.by_tenant_id(%{tenant_id: tenant_id}, page: [count: true, offset: offset_value])

      _other ->
        Group.by_tenant_id(%{tenant_id: tenant_id}, page: [count: true])
    end
  end

  @impl true
  def handle_event("change_page", %{"limit" => limit, "page" => page} = params, socket) do
    {:noreply,
     socket
     |> list_paginated_groups(params, reset_stream: true)
     |> push_patch(
       to: ~p"/tenants/#{socket.assigns.tenant.slug}/groups?page=#{page}&limit=#{limit}"
     )}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    group = Ash.get!(Omedis.Accounts.Group, id)

    Group.destroy(group)

    {:noreply,
     socket
     |> stream_delete(:groups, group)
     |> put_flash(:info, with_locale(socket.assigns.language, fn -> gettext("Group deleted") end))}
  end

  @impl true
  def handle_info({OmedisWeb.GroupLive.FormComponent, {:saved, group}}, socket) do
    {:noreply, stream_insert(socket, :groups, group)}
  end
end
