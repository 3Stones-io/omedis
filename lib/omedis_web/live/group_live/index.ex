defmodule OmedisWeb.GroupLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
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
          <.link patch={~p"/tenants/#{@tenant.slug}/groups/#{group.slug}/edit"} class="font-semibold">
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
    """
  end

  @impl true
  def mount(%{"slug" => slug}, %{"language" => language} = _session, socket) do
    tenant = Tenant.by_slug!(slug)
    groups = Group.by_tenant_id!(%{tenant_id: tenant.id})

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:language, language)
     |> stream(:groups, groups)}
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

  @impl true

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
