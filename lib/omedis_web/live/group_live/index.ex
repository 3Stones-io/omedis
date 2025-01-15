defmodule OmedisWeb.GroupLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Groups
  alias Omedis.Groups.Group
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}
  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

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
            {dgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}", true}
          ]}
          language={@language}
        />

        <div>
          <.link navigate={~p"/organisations/#{@organisation}"} class="button">
            {dgettext("navigation", "Back")}
          </.link>
        </div>
        <.header>
          {dgettext("group", "Listing Groups")}
          <:actions>
            <.link
              :if={
                Ash.can?({Group, :create}, @current_user,
                  actor: @current_user,
                  tenant: @organisation,
                  domain: Groups
                )
              }
              patch={~p"/organisations/#{@organisation}/groups/new"}
            >
              <.button>
                {dgettext("group", "New Group")}
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="groups"
          rows={@streams.groups}
          row_click={
            fn {_id, group} -> JS.navigate(~p"/organisations/#{@organisation}/groups/#{group}") end
          }
        >
          <:col :let={{_id, group}} label={dgettext("group", "Name")}>
            {group.name}
          </:col>

          <:col :let={{_id, group}} label={dgettext("group", "Actions")}>
            <div class="flex gap-4">
              <.link
                :if={
                  Ash.can?({group, :update}, @current_user,
                    actor: @current_user,
                    tenant: @organisation
                  )
                }
                id={"edit-group-#{group.id}"}
                patch={~p"/organisations/#{@organisation}/groups/#{group}/edit"}
                class="font-semibold"
              >
                {dgettext("group", "Edit")}
              </.link>
              <.link
                :if={
                  Ash.can?({group, :destroy}, @current_user,
                    actor: @current_user,
                    tenant: @organisation
                  )
                }
                id={"delete-group-#{group.id}"}
              >
                <p class="font-semibold" phx-click="delete" phx-value-id={group.id}>
                  {dgettext("group", "Delete")}
                </p>
              </.link>
            </div>
          </:col>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="group-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}/groups")}
        >
          <.live_component
            module={OmedisWeb.GroupLive.FormComponent}
            id={(@group && @group) || :new}
            title={@page_title}
            action={@live_action}
            language={@language}
            group={@group}
            current_user={@current_user}
            organisation={@organisation}
            patch={~p"/organisations/#{@organisation}/groups"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/organisations/#{@organisation}/groups"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :groups, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"group_slug" => group_slug}) do
    group =
      Groups.get_group_by_slug!(group_slug,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.organisation
      )

    if Ash.can?({group, :update}, socket.assigns.current_user,
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      socket
      |> assign(
        :page_title,
        dgettext("group", "Edit Group")
      )
      |> assign(:group, group)
    else
      socket
      |> put_flash(
        :error,
        dgettext("group", "You are not authorized to access this page")
      )
      |> redirect(to: ~p"/organisations/#{socket.assigns.organisation}/groups")
    end
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Group, :create}, socket.assigns.current_user,
         actor: socket.assigns.current_user,
         domain: Groups,
         tenant: socket.assigns.organisation
       ) do
      socket
      |> assign(
        :page_title,
        dgettext("group", "New Group")
      )
      |> assign(:group, nil)
    else
      socket
      |> put_flash(
        :error,
        dgettext("group", "You are not authorized to access this page")
      )
      |> redirect(to: ~p"/organisations/#{socket.assigns.organisation}/groups")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      dgettext("group", "Listing Groups")
    )
    |> assign(:group, nil)
    |> PaginationUtils.list_paginated(params, :groups, fn offset ->
      Groups.get_group_by_organisation_id(
        %{organisation_id: socket.assigns.organisation.id},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.organisation
      )
    end)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    group =
      Ash.get!(Omedis.Groups.Group, id,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.organisation
      )

    if Ash.can?({group, :destroy}, socket.assigns.current_user,
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      Groups.destroy_group(group,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.organisation
      )

      {:noreply,
       socket
       |> stream_delete(:groups, group)
       |> put_flash(
         :info,
         dgettext("group", "Group deleted")
       )}
    else
      socket
      |> put_flash(
        :error,
        dgettext("group", "You are not authorized to delete this group")
      )
    end
  end

  @impl true
  def handle_info({OmedisWeb.GroupLive.FormComponent, {:saved, group}}, socket) do
    {:noreply, stream_insert(socket, :groups, group)}
  end
end
