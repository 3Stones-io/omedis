defmodule OmedisWeb.GroupLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Group
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
            <.link
              :if={Ash.can?({Group, :create}, @current_user, actor: @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant.slug}/groups/new"}
            >
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
                :if={Ash.can?({group, :update}, @current_user, actor: @current_user, tenant: @tenant)}
                id={"edit-group-#{group.id}"}
                patch={~p"/tenants/#{@tenant.slug}/groups/#{group.slug}/edit"}
                class="font-semibold"
              >
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit") %>
                <% end) %>
              </.link>
              <.link
                :if={
                  Ash.can?({group, :destroy}, @current_user, actor: @current_user, tenant: @tenant)
                }
                id={"delete-group-#{group.id}"}
              >
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
          resource_path={~p"/tenants/#{@tenant.slug}/groups"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, %{"language" => language} = _session, socket) do
    tenant = Tenant.by_slug!(slug)

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> stream(:groups, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"group_slug" => group_slug}) do
    group =
      Group.by_slug!(group_slug,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.tenant
      )

    if Ash.can?({group, :update}, socket.assigns.current_user,
         actor: socket.assigns.current_user,
         tenant: socket.assigns.tenant
       ) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Group") end)
      )
      |> assign(:group, group)
    else
      socket
      |> put_flash(
        :error,
        with_locale(socket.assigns.language, fn ->
          gettext("You are not authorized to edit this group")
        end)
      )
      |> redirect(to: ~p"/tenants/#{socket.assigns.tenant.slug}/groups")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("New Group") end))
    |> assign(:group, nil)
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Groups") end)
    )
    |> assign(:group, nil)
    |> list_paginated_groups(params)
  end

  defp list_paginated_groups(socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]

    case list_paginated_groups_by_tenant_id(params, opts) do
      {:ok, %{count: total_count, results: groups}} ->
        total_pages = max(1, ceil(total_count / socket.assigns.number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:groups, groups, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_paginated_groups_by_tenant_id(params, opts) do
    tenant_id = opts[:tenant].id

    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        Group.by_tenant_id(
          %{tenant_id: tenant_id},
          opts ++ [page: [count: true, offset: offset_value]]
        )

      _ ->
        Group.by_tenant_id(%{tenant_id: tenant_id}, opts ++ [page: [count: true]])
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    group =
      Ash.get!(Omedis.Accounts.Group, id,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.tenant
      )

    Group.destroy(group, actor: socket.assigns.current_user, tenant: socket.assigns.tenant)

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
