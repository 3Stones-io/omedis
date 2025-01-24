defmodule OmedisWeb.ActivityLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Groups
  alias Omedis.Projects
  alias Omedis.TimeTracking
  alias Omedis.TimeTracking.Activity
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}
  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar current_user={@current_user} organisation={@organisation} language={@language}>
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Groups"), ~p"/groups", false},
            {@group.name, ~p"/groups/#{@group}", false},
            {dgettext("navigation", "Activities"), "", true}
          ]}
          language={@language}
        />

        <.header>
          {dgettext("activity", "Listing Activities")}

          <:actions>
            <.link
              :if={Ash.can?({Activity, :create}, @current_user, tenant: @organisation)}
              patch={~p"/groups/#{@group}/activities/new"}
            >
              <.button>
                {dgettext("activity", "New Activity")}
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="activities"
          rows={@streams.activities}
          row_click={
            fn {_id, activity} ->
              JS.navigate(~p"/groups/#{@group}/activities/#{activity}")
            end
          }
        >
          <:col :let={{_id, activity}} label={dgettext("activity", "Name")}>
            <.custom_color_button color={activity.color_code}>
              {activity.name}
            </.custom_color_button>
          </:col>

          <:col :let={{_id, activity}} label={dgettext("activity", "Position")}>
            <div
              :if={Ash.can?({activity, :update}, @current_user, tenant: @organisation)}
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
                {dgettext("activity", "Default")}
              </span>
            <% end %>
          </:col>

          <:action :let={{_id, activity}}>
            <div class="sr-only">
              <.link navigate={~p"/groups/#{@group}/activities/#{activity}"}>
                {dgettext("activity", "Show")}
              </.link>
            </div>

            <.link
              :if={Ash.can?({activity, :update}, @current_user, tenant: @organisation)}
              patch={~p"/groups/#{@group}/activities/#{activity}/edit"}
            >
              {dgettext("activity", "Edit")}
            </.link>
          </:action>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="activity-modal"
          show
          on_cancel={JS.patch(~p"/groups/#{@group}/activities")}
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={(@activity && @activity.id) || :new}
            current_user={@current_user}
            title={@page_title}
            groups={@groups}
            organisation={@organisation}
            projects={@projects}
            group={@group}
            is_custom_color={@is_custom_color}
            language={@language}
            action={@live_action}
            activity={@activity}
            patch={~p"/groups/#{@group}/activities"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/groups/#{@group}/activities"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  def mount(
        %{"slug" => _slug, "group_slug" => _group_slug},
        %{"language" => language} = _session,
        socket
      ) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Omedis.PubSub, "activity_positions_updated")

    {:ok,
     socket
     |> assign(:language, language)
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
     |> stream(:activities, [])}
  end

  @impl true
  def handle_params(%{"group_slug" => group_slug} = params, _url, socket) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation

    group = Groups.get_group_by_slug!(group_slug, actor: actor, tenant: organisation)
    groups = Groups.get_groups!(actor: actor, tenant: organisation)

    projects =
      Projects.get_project_by_organisation_id!(%{organisation_id: organisation.id},
        actor: actor,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:projects, projects)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    activity = TimeTracking.get_activity_by_id!(id, actor: actor, tenant: organisation)

    if Ash.can?({activity, :update}, actor, tenant: organisation) do
      socket
      |> assign(
        :page_title,
        dgettext("activity", "Edit Activity")
      )
      |> assign(:activity, activity)
    else
      socket
      |> put_flash(
        :error,
        dgettext("activity", "You are not authorized to access this page")
      )
      |> push_navigate(to: ~p"/groups/#{socket.assigns.group}/activities")
    end
  end

  defp apply_action(socket, :new, _params) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation

    if Ash.can?({Activity, :create}, actor, tenant: organisation) do
      socket
      |> assign(
        :page_title,
        dgettext("activity", "New Activity")
      )
      |> assign(:activity, nil)
      |> assign(:is_custom_color, false)
    else
      socket
      |> put_flash(
        :error,
        dgettext("activity", "You are not authorized to access this page")
      )
      |> push_navigate(to: ~p"/groups/#{socket.assigns.group}/activities")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      dgettext("activity", "Listing Activities")
    )
    |> assign(:activity, nil)
    |> assign(:params, params)
    |> list_paginated_activities(params)
  end

  defp list_paginated_activities(socket, params) do
    PaginationUtils.list_paginated(socket, params, :activities, fn offset ->
      TimeTracking.list_paginated_activities(
        %{group_id: socket.assigns.group.id},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.organisation
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
           tenant: socket.assigns.organisation
         ) do
      {:ok, activity} ->
        TimeTracking.move_activity_up(activity,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.organisation
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("move-down", %{"activity-id" => activity_id}, socket) do
    case Ash.get(Activity, activity_id,
           actor: socket.assigns.current_user,
           tenant: socket.assigns.organisation
         ) do
      {:ok, activity} ->
        TimeTracking.move_activity_down(activity,
          actor: socket.assigns.current_user,
          tenant: socket.assigns.organisation
        )

        {:noreply, socket}

      _error ->
        {:noreply, socket}
    end
  end
end
