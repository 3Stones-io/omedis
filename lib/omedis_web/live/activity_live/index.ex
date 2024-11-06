defmodule OmedisWeb.ActivityLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Project
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
            {gettext("Home"), ~p"/", false},
            {gettext("Tenants"), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant}", false},
            {gettext("Groups"), ~p"/tenants/#{@tenant}/groups", false},
            {@group.name, ~p"/tenants/#{@tenant}/groups/#{@group}", false},
            {gettext("Activities"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Activities") %>
          <% end) %>

          <:actions>
            <.link
              :if={Ash.can?({Activity, :create}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant}/groups/#{@group}/activities/new"}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Activity") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="activities"
          rows={@streams.activities}
          row_click={
            fn {_id, activity} ->
              JS.navigate(~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{activity}")
            end
          }
        >
          <:col :let={{_id, activity}} label={with_locale(@language, fn -> gettext("Name") end)}>
            <.custom_color_button color={activity.color_code}>
              <%= activity.name %>
            </.custom_color_button>
          </:col>

          <:col :let={{_id, activity}} label={with_locale(@language, fn -> gettext("Position") end)}>
            <div
              :if={Ash.can?({activity, :update}, @current_user, tenant: @tenant)}
              class="position flex items-center"
            >
              <span class="inline-flex flex-col">
                <button
                  type="button"
                  class="position-up"
                  id={"move-up-#{activity.id}"}
                  phx-click="move-up"
                  phx-value-activity-id={activity.id}
                >
                  <.icon name="hero-arrow-up-circle-solid" class="h-5 w-5 arrow" />
                </button>
                <button
                  type="button"
                  class="position-down"
                  id={"move-down-#{activity.id}"}
                  phx-click="move-down"
                  phx-value-activity-id={activity.id}
                >
                  <.icon name="hero-arrow-down-circle-solid" class="h-5 w-5 arrow" />
                </button>
              </span>
            </div>
          </:col>

          <:col :let={{_id, activity}}>
            <%= if activity.is_default do %>
              <span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
                <%= with_locale(@language, fn -> gettext("Default") end) %>
              </span>
            <% end %>
          </:col>

          <:action :let={{_id, activity}}>
            <div class="sr-only">
              <.link navigate={~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{activity}"}>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Show") %>
                <% end) %>
              </.link>
            </div>

            <.link
              :if={Ash.can?({activity, :update}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{activity}/edit"}
            >
              <%= with_locale(@language, fn -> %>
                <%= gettext("Edit") %>
              <% end) %>
            </.link>
          </:action>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="activity-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant}/groups/#{@group}/activities")}
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={(@activity && @activity.id) || :new}
            current_user={@current_user}
            title={@page_title}
            groups={@groups}
            tenant={@tenant}
            projects={@projects}
            group={@group}
            is_custom_color={@is_custom_color}
            language={@language}
            action={@live_action}
            activity={@activity}
            patch={~p"/tenants/#{@tenant}/groups/#{@group}/activities"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants/#{@tenant}/groups/#{@group}/activities"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  def mount(
        %{"slug" => slug, "group_slug" => group_slug},
        %{"language" => language} = _session,
        socket
      ) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Omedis.PubSub, "activity_positions_updated")

    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)
    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: tenant)

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:tenant, tenant)
     |> assign(:groups, Ash.read!(Group, actor: socket.assigns.current_user, tenant: tenant))
     |> assign(
       :projects,
       Project.by_tenant_id!(%{tenant_id: tenant.id},
         actor: socket.assigns.current_user,
         tenant: tenant
       )
     )
     |> assign(:group, group)
     |> assign(:is_custom_color, false)
     |> stream(:activities, [])}
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Omedis.PubSub, "activity_positions_updated")

    {:ok,
     socket
     |> assign(:current_page, 1)
     |> assign(:language, language)
     |> assign(:total_pages, 0)
     |> assign(:tenants, Ash.read!(Tenant, actor: socket.assigns.current_user))
     |> assign(:tenant, nil)
     |> stream(:activities, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant
    activity = Activity.by_id!(id, actor: actor, tenant: tenant)

    if Ash.can?({activity, :update}, actor, tenant: tenant) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Activity") end)
      )
      |> assign(:activity, activity)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/tenants/#{tenant}/groups/#{socket.assigns.group}/activities")
    end
  end

  defp apply_action(socket, :new, _params) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant

    if Ash.can?({Activity, :create}, actor, tenant: tenant) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("New Activity") end)
      )
      |> assign(:activity, nil)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/tenants/#{tenant}/groups/#{socket.assigns.group}/activities")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Activities") end)
    )
    |> assign(:activity, nil)
    |> assign(:params, params)
    |> list_paginated_activities(params)
  end

  defp list_paginated_activities(socket, params) do
    PaginationUtils.list_paginated(socket, params, :activities, fn offset ->
      Activity.list_paginated(
        %{group_id: socket.assigns.group.id},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.tenant
      )
    end)
  end

  @impl true
  def handle_info({OmedisWeb.ActivityLive.FormComponent, {:saved, activity}}, socket) do
    {:noreply, stream_insert(socket, :activities, activity)}
  end

  @impl true
  def handle_info("updated_positions", socket) do
    {:noreply, list_paginated_activities(socket, Map.get(socket.assigns, :params, %{}))}
  end

  @impl true
  def handle_event("move-up", %{"activity-id" => activity_id}, socket) do
    case Ash.get(Activity, activity_id,
           actor: socket.assigns.current_user,
           tenant: socket.assigns.tenant
         ) do
      {:ok, activity} ->
        Activity.move_up(activity,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.tenant
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("move-down", %{"activity-id" => activity_id}, socket) do
    case Ash.get(Activity, activity_id,
           actor: socket.assigns.current_user,
           tenant: socket.assigns.tenant
         ) do
      {:ok, activity} ->
        Activity.move_down(activity,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.tenant
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end
end
