defmodule OmedisWeb.InvitationLive.Index do
  @moduledoc false

  use OmedisWeb, :live_view

  alias Omedis.Accounts.Invitation
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
        <.breadcrumb
          items={[
            {with_locale(@language, fn -> gettext("Home") end), ~p"/", false},
            {with_locale(@language, fn -> gettext("Tenants") end), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant.slug}", false},
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
            resource_path={~p"/tenants/#{@tenant.slug}/invitations"}
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
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> list_paginated_invitations(params)}
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
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]

    params = %{"sort_order" => new_sort_order, "creator_id" => opts[:actor].id}
    maybe_updated_socket = list_paginated_invitations(socket, params)

    {:noreply,
     maybe_updated_socket
     |> assign(:sort_order, new_sort_order)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Invitations") end)
    )
  end

  defp list_paginated_invitations(socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]

    sort_order =
      params
      |> Map.get("sort_order", "asc")
      |> String.to_existing_atom()

    updated_params =
      params
      |> Map.put("creator_id", socket.assigns.current_user.id)
      |> Map.put("sort_order", sort_order)

    case list_invitations(updated_params, opts) do
      {:ok, %{count: total_count, results: invitations}} ->
        total_pages = max(1, ceil(total_count / socket.assigns.number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:invitations, invitations, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_invitations(params, opts) do
    updated_params = Map.drop(params, ["page", "slug"])

    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        Invitation.list_paginated(
          updated_params,
          opts ++ [page: [offset: offset_value, limit: 10, count: true]]
        )

      _ ->
        Invitation.list_paginated(
          updated_params,
          opts ++ [page: [offset: 0, limit: 10, count: true]]
        )
    end
  end
end
