defmodule OmedisWeb.InvitationLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.Invitation

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:tenant, tenant)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Invitation, :create}, socket.assigns.current_user, tenant: socket.assigns.tenant) do
      socket
      |> assign(
        :page_title,
        with_locale(
          socket.assigns.language,
          fn -> gettext("New Invitation") end
        )
      )
      |> assign(:invitation, nil)
    else
      # TODO: Redirect to the invitations index page
      push_navigate(socket, to: ~p"/tenants/#{socket.assigns.tenant.slug}")
    end
  end

  defp apply_action(socket, _, _params) do
    socket
    |> push_navigate(to: ~p"/tenants/#{socket.assigns.tenant.slug}/invitations/new")
  end

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
        <.breadcrumb
          items={[
            {gettext("Home"), ~p"/", false},
            {gettext("Tenants"), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant.slug}", false},
            {gettext("Invitations"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= @page_title %>
        </.header>

        <.live_component
          module={OmedisWeb.InvitationLive.FormComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          tenant={@tenant}
          language={@language}
          current_user={@current_user}
          patch={~p"/tenants/#{@tenant.slug}"}
        />
      </div>
    </.side_and_topbar>
    """
  end
end
