defmodule OmedisWeb.InvitationLive.Index do
  @moduledoc false

  use OmedisWeb, :live_view

  alias Omedis.Invitations
  alias OmedisWeb.Endpoint
  alias OmedisWeb.InvitationLive.InvitationStatusComponent
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils
  alias Phoenix.Socket.Broadcast

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}
  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Endpoint.subscribe("#{socket.assigns.current_organisation.id}:invitations")
    end

    {:ok,
     socket
     |> assign(:sort_order, :desc)
     |> stream(:invitations, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    sort_order =
      params
      |> Map.get("sort_order", "asc")
      |> String.to_existing_atom()

    socket
    |> assign(:sort_order, Atom.to_string(sort_order))
    |> PaginationUtils.list_paginated(params, :invitations, fn offset ->
      Invitations.list_paginated_invitations(
        %{sort_order: sort_order},
        page: [count: true, offset: offset],
        actor: socket.assigns.current_user,
        tenant: socket.assigns.organisation
      )
    end)
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Invitations.Invitation, :create}, socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      socket
      |> assign(:invitation, nil)
    else
      push_navigate(socket, to: ~p"/organisations/#{socket.assigns.organisation}/invitations")
    end
  end

  defp apply_action(socket, _, _params) do
    socket
    |> push_navigate(to: ~p"/organisations/#{socket.assigns.organisation}/invitations/new")
  end

  @impl true
  def handle_event("delete_invitation", %{"id" => id}, socket) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.organisation]
    invitation = Invitations.get_invitation_by_id!(id, opts)
    :ok = Invitations.delete_invitation!(invitation, opts)

    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext("invitation", "Invitation deleted successfully")
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
       Invitations.list_paginated_invitations(
         params,
         page: [count: true, offset: offset],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       )
     end)
     |> assign(:sort_order, new_sort_order)}
  end

  @impl true
  def handle_info(%Broadcast{event: "accept"} = broadcast, socket) do
    accepted_invitation = Map.get(broadcast.payload, :data)
    {:noreply, stream_insert(socket, :invitations, accepted_invitation)}
  end

  def handle_info(%Broadcast{event: "create"} = broadcast, socket) do
    created_invitation = Map.get(broadcast.payload, :data)
    {:noreply, stream_insert(socket, :invitations, created_invitation)}
  end

  def handle_info(%Broadcast{event: "destroy"} = broadcast, socket) do
    deleted_invitation = Map.get(broadcast.payload, :data)
    {:noreply, stream_delete(socket, :invitations, deleted_invitation)}
  end

  def handle_info(%Broadcast{event: "expire"} = broadcast, socket) do
    expired_invitation = Map.get(broadcast.payload, :data)
    {:noreply, stream_insert(socket, :invitations, expired_invitation)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Invitations"), "", true}
          ]}
          language={@language}
        />

        <.header>
          {dgettext("invitation", "Listing Invitations")}

          <:actions>
            <.link
              :if={Ash.can?({Invitations.Invitation, :create}, @current_user, tenant: @organisation)}
              patch={~p"/organisations/#{@organisation}/invitations/new"}
            >
              <.button>
                {dgettext("invitation", "New Invitation")}
              </.button>
            </.link>
          </:actions>
        </.header>

        <.modal
          :if={@live_action == :new}
          id="invitation-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}/invitations")}
        >
          <.live_component
            module={OmedisWeb.InvitationLive.FormComponent}
            id={:new}
            action={@live_action}
            organisation={@organisation}
            language={@language}
            current_user={@current_user}
            patch={~p"/organisations/#{@organisation}/invitations"}
          />
        </.modal>

        <div class="overflow-x-auto">
          <.table id="invitations" rows={@streams.invitations}>
            <:col :let={{_id, invitation}} label={dgettext("invitation", "Email")}>
              {invitation.email}
            </:col>

            <:col :let={{_id, invitation}} label={dgettext("invitation", "Status")}>
              <InvitationStatusComponent.status status={invitation.status} />
            </:col>

            <:col
              :let={{_id, invitation}}
              label={dgettext("invitation", "Invited At")}
              sort_by={(@sort_order == "asc" && "↓") || "↑"}
              col_click={
                JS.push("sort_invitations",
                  value: %{
                    current_sort_order: @sort_order
                  }
                )
              }
            >
              {Calendar.strftime(invitation.inserted_at, "%Y-%m-%d %H:%M:%S")}
            </:col>

            <:col :let={{_id, invitation}} label={dgettext("invitation", "Expires At")}>
              {Calendar.strftime(invitation.expires_at, "%Y-%m-%d %H:%M:%S")}
            </:col>

            <:action :let={{dom_id, invitation}}>
              <.link
                :if={Ash.can?({invitation, :destroy}, @current_user, tenant: @organisation)}
                id={"delete_invitation_#{invitation.id}"}
                phx-click={
                  JS.push("delete_invitation", value: %{id: invitation.id}) |> hide("##{dom_id}")
                }
                data-confirm={
                  dgettext("invitation", "Are you sure you want to delete this invitation?")
                }
                class="text-red-600 hover:text-red-900"
              >
                {dgettext("invitation", "Delete")}
              </.link>
            </:action>
          </.table>
        </div>

        <div class="mt-6">
          <PaginationComponent.pagination
            current_page={@current_page}
            language={@language}
            resource_path={~p"/organisations/#{@organisation}/invitations"}
            total_pages={@total_pages}
          />
        </div>
      </div>
    </.side_and_topbar>
    """
  end
end
