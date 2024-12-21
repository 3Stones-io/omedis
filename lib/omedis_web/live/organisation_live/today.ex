defmodule OmedisWeb.OrganisationLive.Today do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Project
  alias Omedis.Groups.Group
  alias Omedis.TimeTracking.Activity
  alias Omedis.TimeTracking.Event
  alias OmedisWeb.Endpoint

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}

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
            {dgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}/groups", false},
            {@group.name, ~p"/organisations/#{@organisation}/groups/#{@group}", false},
            {dgettext("navigation", "Today"), "", true}
          ]}
          language={@language}
        />

        <.select_for_groups_and_project
          groups={@groups}
          group={@group}
          project={@project}
          language={@language}
          projects={@projects}
          header_text={dgettext("organisation", "Select group and project")}
        />

        <.dashboard_component
          current_activity_id={@current_activity_id}
          activities={@activities}
          start_at={@start_at}
          end_at={@end_at}
          events={@events}
          language={@language}
          current_time={@current_time}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = session, socket) do
    if connected?(socket) do
      :ok = Endpoint.subscribe("current_activity_#{session["pubsub_topics_unique_id"]}")
    end

    {:ok,
     socket
     |> assign(:language, language)
     |> assign(:pubsub_topics_unique_id, session["pubsub_topics_unique_id"])}
  end

  @impl true
  def handle_params(%{"group_id" => id, "project_id" => project_id}, _, socket) do
    current_user = socket.assigns.current_user
    organisation = socket.assigns.organisation
    group = Group.by_id!(id, tenant: organisation, actor: current_user)
    project = Project.by_id!(project_id, tenant: organisation, actor: current_user)

    # Update the timestamps for the group and project,
    # so they become the latest ones
    {:ok, updated_group} =
      Group.update(group,
        actor: current_user,
        context: %{updated_at: DateTime.utc_now()},
        tenant: organisation
      )

    {:ok, updated_project} =
      Project.update(project,
        actor: current_user,
        context: %{updated_at: DateTime.utc_now()},
        tenant: organisation
      )

    {:ok, %{results: events}} =
      Event.list_paginated_today(actor: current_user, tenant: organisation)

    {min_start_in_events, max_end_in_events} =
      if Enum.empty?(events) do
        {nil, nil}
      else
        get_time_range(events)
      end

    start_at =
      (get_start_time_to_use(min_start_in_events, current_user.daily_start_at) ||
         organisation.default_daily_start_at)
      |> format_timezone(organisation.timezone)
      |> round_down_start_at()

    end_at =
      (get_end_time_to_use(max_end_in_events, current_user.daily_end_at) ||
         organisation.default_daily_end_at)
      |> format_timezone(organisation.timezone)
      |> round_up_end_at()

    activities = activities(group.id, project.id, actor: current_user, tenant: organisation)

    events = format_events(activities, organisation)

    current_time = Time.utc_now() |> format_timezone(organisation.timezone)

    {:noreply,
     socket
     |> assign(:current_time, current_time)
     |> assign(:page_title, "Today")
     |> assign(:start_at, start_at)
     |> assign(:end_at, end_at)
     |> assign(:groups, groups_for_an_organisation(organisation, current_user))
     |> assign(:projects, projects_for_an_organisation(organisation, current_user))
     |> assign(:group, updated_group)
     |> assign(:project, updated_project)
     |> assign(:events, events)
     |> assign_current_activity(activities)
     |> assign(:activities, activities)}
  end

  @impl true
  def handle_params(_params, _, socket) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.organisation]

    with {:ok, group} <- latest_group_for_an_organisation(socket, opts),
         {:ok, project} <- latest_project_for_an_organisation(socket, opts) do
      {:noreply,
       socket
       |> push_navigate(
         to:
           ~p"/organisations/#{socket.assigns.organisation}/today?group_id=#{group.id}&project_id=#{project.id}"
       )}
    end
  end

  # Defaults to German Timezone
  defp format_timezone(time, nil), do: Time.add(time, 2, :hour)

  defp format_timezone(time, timezone) do
    regex = ~r/GMT([+-]\d{2})/

    offset =
      case Regex.run(regex, timezone) do
        # Convert the extracted "+03" into an integer (+3)
        [_, offset] -> String.to_integer(offset)
        _ -> "No match"
      end

    Time.add(time, offset, :hour)
  end

  defp assign_current_activity(socket, activities) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.organisation]
    events = get_active_event(activities, opts)

    if Enum.empty?(events) do
      assign(socket, :current_activity_id, nil)
    else
      activity_id = List.first(events).activity_id
      assign(socket, :current_activity_id, activity_id)
    end
  end

  defp get_active_event(activities, opts) do
    activities
    |> Stream.map(fn activity ->
      {:ok, events} =
        Event.by_activity_today(%{activity_id: activity.id}, opts)

      Enum.filter(events, &is_nil(&1.dtend))
    end)
    |> Stream.filter(&(!Enum.empty?(&1)))
    |> Enum.to_list()
    |> List.flatten()
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "event_started", payload: activity}, socket) do
    {:noreply, assign(socket, :current_activity_id, activity.id)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "event_stopped"}, socket) do
    {:noreply, assign(socket, :current_activity_id, nil)}
  end

  defp get_start_time_to_use(nil, daily_start_at), do: daily_start_at

  defp get_start_time_to_use(min_start_in_events, daily_start_at)
       when not is_nil(daily_start_at) do
    if Time.compare(min_start_in_events, daily_start_at) == :lt do
      min_start_in_events
    else
      daily_start_at
    end
  end

  defp get_start_time_to_use(_, _), do: nil

  defp get_end_time_to_use(nil, daily_end_at), do: daily_end_at

  defp get_end_time_to_use(max_end_in_events, daily_end_at) when not is_nil(daily_end_at) do
    if Time.compare(max_end_in_events, daily_end_at) == :gt do
      max_end_in_events
    else
      daily_end_at
    end
  end

  defp get_end_time_to_use(_, _), do: nil

  defp format_events(activities, organisation) do
    activities
    |> Enum.map(fn activity ->
      activity.events
    end)
    |> List.flatten()
    |> Enum.filter(fn event ->
      event.created_at |> DateTime.to_date() == Date.utc_today()
    end)
    |> Enum.sort_by(fn %{dtstart: dtstart, dtend: dtend} -> {dtstart, dtend} end)
    |> Enum.map(fn x ->
      %{
        id: x.id,
        dtstart: x.dtstart |> format_timezone(organisation.timezone),
        dtend: get_end_time_in_event(x.dtend) |> format_timezone(organisation.timezone),
        activity_id: x.activity_id,
        color_code:
          Enum.find(activities, fn activity ->
            activity.events |> Enum.find(fn event -> event.dtstart == x.dtstart end)
          end).color_code
      }
    end)
  end

  defp get_end_time_in_event(nil) do
    Time.utc_now()
  end

  defp get_end_time_in_event(end_time) do
    end_time
  end

  defp activities(group_id, project_id, opts) do
    case Activity.by_group_id_and_project_id(
           %{group_id: group_id, project_id: project_id},
           opts
         ) do
      {:ok, activities} ->
        activities

      _ ->
        []
    end
  end

  defp get_time_range(events) do
    events =
      events
      |> Enum.map(fn x ->
        %{
          start_at: x.dtstart,
          end_at: get_end_time_in_event(x.dtend)
        }
      end)

    Enum.reduce(events, {nil, nil}, fn event, {min_start, max_end} ->
      start_at = event.start_at
      end_at = event.end_at

      min_start = get_min_start(min_start, start_at)

      max_end =
        get_max_end(max_end, end_at)

      {
        min_start,
        max_end
      }
    end)
  end

  defp get_min_start(min_start, start_at) do
    case min_start do
      nil -> start_at
      _ -> if Time.compare(start_at, min_start) == :lt, do: start_at, else: min_start
    end
  end

  defp get_max_end(max_end, end_at) do
    case max_end do
      nil -> end_at
      _ -> if Time.compare(end_at, max_end) == :gt, do: end_at, else: max_end
    end
  end

  def round_down_start_at(start_at) do
    Time.new!(start_at.hour, 0, 0)
  end

  def round_up_end_at(end_at) do
    if end_at.minute > 0 or end_at.second > 0 do
      Time.add(Time.new!(end_at.hour, 0, 0), 3600, :second)
    else
      Time.new!(end_at.hour, 0, 0)
    end
  end

  @impl true
  def handle_event("start_activity", %{"activity_id" => activity_id}, socket) do
    if socket.assigns.current_activity_id do
      event_stop_time = DateTime.add(DateTime.utc_now(), -1, :second)

      {:noreply,
       socket
       |> stop_any_active_event(event_stop_time: event_stop_time)
       |> create_event(activity_id)}
    else
      {:noreply, create_event(socket, activity_id)}
    end
  end

  def handle_event("stop_current_activity", _params, socket) do
    {:noreply, stop_any_active_event(socket)}
  end

  def handle_event("select_group", %{"group_id" => id}, socket) do
    {:noreply,
     socket
     |> push_navigate(
       to:
         ~p"/organisations/#{socket.assigns.organisation}/today?group_id=#{id}&project_id=#{socket.assigns.project.id}"
     )}
  end

  def handle_event("select_project", %{"project_id" => id}, socket) do
    {:noreply,
     socket
     |> push_navigate(
       to:
         ~p"/organisations/#{socket.assigns.organisation}/today?group_id=#{socket.assigns.group.id}&project_id=#{id}"
     )}
  end

  defp stop_any_active_event(socket, event_stop_time \\ DateTime.utc_now()) do
    {:ok, events} =
      Event.by_activity_today(%{activity_id: socket.assigns.current_activity_id},
        actor: socket.assigns.current_user,
        tenant: socket.assigns.organisation
      )

    case Enum.find(events, fn event -> event.dtend == nil end) do
      nil ->
        socket

      event ->
        stop_event(socket, event,
          actor: socket.assigns.current_user,
          event_stop_time: event_stop_time,
          tenant: socket.assigns.organisation
        )
    end
  end

  defp create_event(socket, activity_id) do
    organisation = socket.assigns.organisation
    user = socket.assigns.current_user
    {:ok, activity} = Activity.by_id(activity_id, actor: user, tenant: organisation)

    if Ash.can?({Event, :create}, user, tenant: organisation) do
      {:ok, _event} =
        Event.create(
          %{
            activity_id: activity_id,
            dtstart: DateTime.utc_now(),
            summary: activity.name,
            user_id: user.id
          },
          actor: user,
          tenant: organisation
        )

      :ok =
        Endpoint.broadcast(
          "current_activity_#{socket.assigns.pubsub_topics_unique_id}",
          "event_started",
          activity
        )

      assign(socket, :current_activity_id, activity_id)
    else
      put_flash(
        socket,
        :error,
        dgettext(
          "organisation",
          "You are not authorized to perform this action"
        )
      )
    end
  end

  def stop_event(socket, event, opts) do
    if Ash.can?({event, :update}, socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      {:ok, _event} =
        Event.update(event, %{dtend: opts[:event_stop_time]},
          actor: opts[:actor],
          tenant: opts[:tenant]
        )

      :ok =
        Endpoint.broadcast(
          "current_activity_#{socket.assigns.pubsub_topics_unique_id}",
          "event_stopped",
          %{}
        )

      assign(socket, :current_activity_id, nil)
    else
      put_flash(
        socket,
        :error,
        dgettext(
          "organisation",
          "You are not authorized to perform this action"
        )
      )
    end
  end

  defp latest_group_for_an_organisation(socket, opts) do
    organisation = socket.assigns.organisation

    case Group.latest_by_organisation_id(%{organisation_id: organisation.id}, opts) do
      {:ok, [group]} ->
        {:ok, group}

      {:ok, []} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("group", "No group found. Please create one first."))
         |> push_navigate(to: ~p"/organisations/#{organisation}/groups/new")}
    end
  end

  defp latest_project_for_an_organisation(socket, opts) do
    organisation = socket.assigns.organisation

    case Project.latest_by_organisation_id(%{organisation_id: organisation.id}, opts) do
      {:ok, [project]} ->
        {:ok, project}

      {:ok, []} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("project", "No project found. Please create one first."))
         |> push_navigate(to: ~p"/organisations/#{organisation}/projects/new")}
    end
  end

  defp groups_for_an_organisation(organisation, current_user) do
    case Group.by_organisation_id(%{organisation_id: organisation.id},
           actor: current_user,
           tenant: organisation
         ) do
      {:ok, %{results: groups}} ->
        groups
        |> Enum.map(fn group -> {group.name, group.id} end)

      _ ->
        []
    end
  end

  defp projects_for_an_organisation(organisation, current_user) do
    case Project.by_organisation_id(%{organisation_id: organisation.id},
           actor: current_user,
           tenant: organisation
         ) do
      {:ok, projects} ->
        projects
        |> Enum.map(fn project -> {project.name, project.id} end)

      _ ->
        []
    end
  end
end
