defmodule OmedisWeb.GroupLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Tenant

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
          {@group.name, "", true}
        ]} />

        <.header>
          <:actions>
            <.link
              patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/log_categories"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Log categories") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> gettext("Name") end)}><%= @group.name %></:item>
          <:item title={with_locale(@language, fn -> gettext("Slug") end)}><%= @group.slug %></:item>
        </.list>

        <.back navigate={~p"/tenants/#{@tenant.slug}/groups"}>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Back to groups") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="group-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}")}
        >
          <.live_component
            module={OmedisWeb.GroupLive.FormComponent}
            id={@group.id}
            title={@page_title}
            action={@live_action}
            tenant={@tenant}
            language={@language}
            group={@group}
            patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}"}
          />
        </.modal>
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:page_title, page_title(socket.assigns.live_action, language))}
  end

  @impl true
  def handle_params(%{"slug" => slug, "group_slug" => group_slug}, _, socket) do
    tenant = Tenant.by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:tenant, tenant)
     |> assign(
       :group,
       Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: tenant)
     )}
  end

  defp page_title(:show, language), do: with_locale(language, fn -> gettext("Show Tenant") end)
  defp page_title(:edit, language), do: with_locale(language, fn -> gettext("Edit Tenant") end)
end
