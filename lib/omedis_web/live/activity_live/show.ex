defmodule OmedisWeb.ActivityLive.Show do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Organisation
  alias Omedis.Groups
  alias Omedis.Projects
  alias Omedis.TimeTracking

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar current_user={@current_user} organisation={@organisation} language={@language}>
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Groups"), ~p"/groups", false},
            {@group.name, ~p"/groups/#{@group}", false},
            {dgettext("navigation", "Activities"), ~p"/groups/#{@group}/activities", false},
            {@activity.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          {dgettext("activity", "Activity")}

          <:subtitle>
            {dgettext(
              "activity",
              "This is an activity record from your database."
            )}
          </:subtitle>

          <:actions>
            <.link
              patch={~p"/groups/#{@group}/activities/#{@activity}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button>
                {dgettext("activity", "Edit Activity")}
              </.button>
            </.link>

            <.link navigate={~p"/activities/#{@activity}/events"} phx-click={JS.push_focus()}>
              <.button>
                {dgettext("activity", "View Events")}
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={dgettext("activity", "Name")}>
            {@activity.name}
          </:item>

          <:item title={dgettext("activity", "Color Code")}>
            {@activity.color_code}
          </:item>

          <:item title={dgettext("activity", "Position")}>
            {@activity.position}
          </:item>
        </.list>

        <.back navigate={~p"/groups/#{@group}/activities"}>
          {dgettext("activity", "Back to activities")}
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="activity-modal"
          show
          on_cancel={JS.patch(~p"/groups/#{@group}/activities/#{@activity}")}
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={@activity.id}
            current_user={@current_user}
            projects={@projects}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            groups={@groups}
            color_code={@color_code}
            is_custom_color={@is_custom_color}
            organisations={@organisations}
            group={@group}
            next_position={@next_position}
            language={@language}
            activity={@activity}
            patch={~p"/groups/#{@group}/activities/#{@activity}"}
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
     |> assign(:language, language)}
  end

  @impl true
  def handle_params(%{"id" => id, "group_slug" => group_slug}, _, socket) do
    organisation = socket.assigns.organisation

    group =
      Groups.get_group_by_slug!(group_slug,
        actor: socket.assigns.current_user,
        tenant: organisation
      )

    groups = Groups.get_groups!(actor: socket.assigns.current_user, tenant: organisation)

    activity =
      TimeTracking.get_activity_by_id!(id,
        actor: socket.assigns.current_user,
        tenant: organisation
      )

    next_position = activity.position

    projects =
      Projects.get_project_by_organisation_id!(%{organisation_id: organisation.id},
        actor: socket.assigns.current_user,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:activity, activity)
     |> assign(:organisations, Ash.read!(Organisation, actor: socket.assigns.current_user))
     |> assign(:projects, projects)
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:is_custom_color, true)
     |> assign(:color_code, activity.color_code)
     |> assign(:next_position, next_position)
     |> apply_action(socket.assigns.live_action)}
  end

  defp page_title(:show),
    do: dgettext("activity", "Show Activity")

  defp page_title(:edit),
    do: dgettext("activity", "Edit Activity")

  defp apply_action(socket, :edit) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    activity = socket.assigns.activity

    if Ash.can?({activity, :update}, actor, tenant: organisation) do
      assign(socket, :page_title, page_title(:edit))
    else
      socket
      |> put_flash(
        :error,
        dgettext("activity", "You are not authorized to access this page")
      )
      |> push_navigate(to: ~p"/groups/#{socket.assigns.group}/activities/#{activity.id}")
    end
  end

  defp apply_action(socket, _), do: socket
end
