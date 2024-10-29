defmodule OmedisWeb.TenantLive.Index do
  use OmedisWeb, :live_view
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
        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Tenants") %>
          <% end) %>
          <:actions>
            <.link :if={Ash.can?({Tenant, :create}, @current_user)} patch={~p"/tenants/new"}>
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
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants"}
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
     |> stream(:tenants, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

    if Ash.can?({tenant, :update}, socket.assigns.current_user) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Tenant") end)
      )
      |> assign(:tenant, tenant)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/tenants")
    end
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Tenant, :create}, socket.assigns.current_user) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("New Tenant") end)
      )
      |> assign(:tenant, nil)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized access this page"))
      |> push_navigate(to: ~p"/tenants")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Tenants") end)
    )
    |> assign(:tenant, nil)
    |> PaginationUtils.list_paginated(params, :tenants, fn offset ->
      Tenant.list_paginated(
        page: [count: true, offset: offset],
        actor: socket.assigns.current_user
      )
    end)
  end

  @impl true
  def handle_info({OmedisWeb.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply,
     socket
     |> assign(:tenants_count, socket.assigns.tenants_count + 1)
     |> stream_insert(:tenants, tenant)}
  end
end
