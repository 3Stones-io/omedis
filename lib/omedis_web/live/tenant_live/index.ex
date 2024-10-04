defmodule OmedisWeb.TenantLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
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
          <%= tenant.website %>
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
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    socket =
      socket
      |> assign(:language, language)

    {:ok, current_user_with_tenants} = Ash.load(socket.assigns.current_user, [:tenants])
    {:ok, stream(socket, :tenants, current_user_with_tenants.tenants)}
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

  @impl true
  def handle_info({OmedisWeb.TenantLive.FormComponent, {:saved, tenant}}, socket) do
    {:noreply, stream_insert(socket, :tenants, tenant)}
  end
end
