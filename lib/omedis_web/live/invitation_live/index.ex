defmodule OmedisWeb.InvitationLive.Index do
  @moduledoc false

  use OmedisWeb, :live_view

  alias Omedis.Accounts.Invitation
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
        <.breadcrumb
          items={[
            {with_locale(@language, fn -> gettext("Home") end), ~p"/", false},
            {with_locale(@language, fn -> gettext("Tenants") end), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant}", false},
            {with_locale(@language, fn -> gettext("Invitations") end), "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> gettext("Listing Invitations") end) %>
        </.header>

        <div class="overflow-x-auto">
          <.table id="invitations" rows={@streams.invitations}>
            <:col :let={{_id, invitation}} label={with_locale(@language, fn -> gettext("Email") end)}>
              <%= invitation.email %>
            </:col>

            <:col :let={{_id, invitation}} label={with_locale(@language, fn -> gettext("Status") end)}>
              <%= if invitation.user_id do %>
                <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                  <%= with_locale(@language, fn -> gettext("Accepted") end) %>
                </span>
              <% else %>
                <span class="inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-700 ring-1 ring-inset ring-yellow-600/20">
                  <%= with_locale(@language, fn -> gettext("Pending") end) %>
                </span>
              <% end %>
            </:col>

            <:col
              :let={{_id, invitation}}
              label={with_locale(@language, fn -> gettext("Invited At") end)}
              sort_by={(@sort_order == "asc" && "↓") || "↑"}
              col_click={
                JS.push("sort_invitations",
                  value: %{
                    current_sort_order: @sort_order
                  }
                )
              }
            >
              <%= Calendar.strftime(invitation.inserted_at, "%Y-%m-%d %H:%M:%S") %>
            </:col>

            <:col
              :let={{_id, invitation}}
              label={with_locale(@language, fn -> gettext("Expires At") end)}
            >
              <%= Calendar.strftime(invitation.expires_at, "%Y-%m-%d %H:%M:%S") %>
            </:col>

            <:action :let={{dom_id, invitation}}>
              <.link
                :if={Ash.can?({invitation, :destroy}, @current_user, tenant: @tenant)}
                id={"delete_invitation_#{invitation.id}"}
                phx-click={
                  JS.push("delete_invitation", value: %{id: invitation.id}) |> hide("##{dom_id}")
                }
                data-confirm={
                  with_locale(@language, fn ->
                    gettext("Are you sure you want to delete this invitation?")
                  end)
                }
                class="text-red-600 hover:text-red-900"
              >
                <%= with_locale(@language, fn -> gettext("Delete") end) %>
              </.link>
            </:action>
          </.table>
        </div>

        <div class="mt-6">
          <PaginationComponent.pagination
            current_page={@current_page}
            language={@language}
            resource_path={~p"/tenants/#{@tenant}/invitations"}
            total_pages={@total_pages}
          />
        </div>
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:sort_order, :desc)
     |> stream(:invitations, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete_invitation", %{"id" => id}, socket) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]
    invitation = Invitation.by_id!(id, opts)
    :ok = Invitation.destroy!(invitation, opts)

    {:noreply,
     socket
     |> put_flash(
       :info,
       with_locale(socket.assigns.language, fn -> gettext("Invitation deleted successfully") end)
     )
     |> stream_delete(:invitations, invitation)}
  end

  @impl true
  def handle_event("sort_invitations", %{"current_sort_order" => current_sort_order}, socket) do
    new_sort_order = if current_sort_order == "asc", do: "desc", else: "asc"
    params = %{sort_order: String.to_atom(new_sort_order)}

    {:noreply,
     socket
     |> PaginationUtils.list_paginated(params, :invitations, fn offset ->
       Invitation.list_paginated(
         params,
         page: [count: true, offset: offset],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.tenant
       )
     end)
     |> assign(:sort_order, new_sort_order)}
  end

  defp apply_action(socket, :index, params) do
    sort_order =
      params
      |> Map.get("sort_order", "asc")
      |> String.to_existing_atom()

    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Invitations") end)
    )
    |> assign(:sort_order, Atom.to_string(sort_order))
    |> PaginationUtils.list_paginated(params, :invitations, fn offset ->
      Invitation.list_paginated(
        %{sort_order: sort_order},
        page: [count: true, offset: offset],
        actor: socket.assigns.current_user,
        tenant: socket.assigns.tenant
      )
    end)
  end
end
