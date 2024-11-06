defmodule OmedisWeb.TenantLive.Today do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogEntry
  alias Omedis.Accounts.Project
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
        <.breadcrumb
          items={[
            {gettext("Home"), ~p"/", false},
            {gettext("Tenants"), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant}", false},
            {gettext("Groups"), ~p"/tenants/#{@tenant}/groups", false},
            {@group.name, ~p"/tenants/#{@tenant}/groups/#{@group}", false},
            {gettext("Today"), "", true}
          ]}
          language={@language}
        />

        <.select_for_groups_and_project
          groups={@groups}
          group={@group}
          project={@project}
          language={@language}
          projects={@projects}
          header_text={with_locale(@language, fn -> gettext("Select group and project") end)}
        />

        <.dashboard_component
          active_activity_id={@active_activity_id}
          activities={@activities}
          start_at={@start_at}
          end_at={@end_at}
          log_entries={@log_entries}
          language={@language}
          current_time={@current_time}
        />
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
  def handle_params(%{"group_id" => id, "project_id" => project_id, "slug" => slug}, _, socket) do
    current_user = socket.assigns.current_user
    tenant = Tenant.by_slug!(slug, actor: current_user)
    group = Group.by_id!(id, tenant: tenant, actor: current_user)
    project = Project.by_id!(project_id, tenant: tenant, actor: current_user)

    {min_start_in_entries, max_end_in_entries} =
      get_time_range(
        LogEntry.by_tenant_today!(%{tenant_id: tenant.id}, actor: current_user, tenant: tenant)
      )

    start_at =
      get_start_time_to_use(min_start_in_entries, current_user.daily_start_at)
      |> format_timezone(tenant.timezone)
      |> round_down_start_at()

    end_at =
      get_end_time_to_use(max_end_in_entries, current_user.daily_end_at)
      |> format_timezone(tenant.timezone)
      |> round_up_end_at()

    update_activities_and_current_time_every_minute()

    activities = activities(group.id, project.id, actor: current_user, tenant: tenant)

    log_entries = format_entries(activities, tenant)

    current_time = Time.utc_now() |> format_timezone(tenant.timezone)

    {:noreply,
     socket
     |> assign(:current_time, current_time)
     |> assign(:page_title, "Today")
     |> assign(:tenant, tenant)
     |> assign(:start_at, start_at)
     |> assign(:end_at, end_at)
     |> assign(:groups, groups_for_a_tenant(tenant.id))
     |> assign(:projects, projects_for_a_tenant(tenant, current_user))
     |> assign(:group, group)
     |> assign(:project, project)
     |> assign(:log_entries, log_entries)
     |> assign_active_activity(activities)
     |> assign(:activities, activities)}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)
    group = latest_group_for_a_tenant(tenant.id)
    project = latest_project_for_a_tenant(tenant, socket.assigns.current_user)

    {:noreply,
     socket
     |> push_navigate(
       to: "/tenants/#{tenant}/today?group_id=#{group.id}&project_id=#{project.id}"
     )}
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

  defp assign_active_activity(socket, activities) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]
    entries = get_active_entry(activities, opts)

    if Enum.empty?(entries) do
      assign(socket, :active_activity_id, nil)
    else
      activity_id = List.first(entries).activity_id
      assign(socket, :active_activity_id, activity_id)
    end
  end

  defp get_active_entry(activities, opts) do
    activities
    |> Stream.map(fn activity ->
      {:ok, log_entries} =
        LogEntry.by_activity_today(%{activity_id: activity.id}, opts)

      Enum.filter(log_entries, &is_nil(&1.end_at))
    end)
    |> Stream.filter(&(!Enum.empty?(&1)))
    |> Enum.to_list()
    |> List.flatten()
  end

  @impl true
  def handle_info(:update_activities_and_current_time, socket) do
    tenant = socket.assigns.tenant
    group = socket.assigns.group
    current_user = socket.assigns.current_user
    project = socket.assigns.project

    activities = activities(group.id, project.id, actor: current_user, tenant: tenant)

    log_entries =
      format_entries(activities, tenant)

    {min_start_in_entries, max_end_in_entries} =
      get_time_range(
        LogEntry.by_tenant_today!(%{tenant_id: tenant.id}, actor: current_user, tenant: tenant)
      )

    start_at =
      get_start_time_to_use(min_start_in_entries, current_user.daily_start_at)
      |> format_timezone(tenant.timezone)
      |> round_down_start_at()

    end_at =
      get_end_time_to_use(max_end_in_entries, current_user.daily_end_at)
      |> format_timezone(tenant.timezone)
      |> round_up_end_at()

    current_time = Time.utc_now() |> format_timezone(tenant.timezone)

    {:noreply,
     socket
     |> assign(:activities, activities)
     |> assign(:log_entries, log_entries)
     |> assign(:start_at, start_at)
     |> assign(:end_at, end_at)
     |> assign(:current_time, current_time)}
  end

  defp update_activities_and_current_time_every_minute do
    :timer.send_interval(1000, self(), :update_activities_and_current_time)
  end

  defp get_start_time_to_use(nil, daily_start_at) do
    daily_start_at
  end

  defp get_start_time_to_use(min_start_in_entries, daily_start_at) do
    if Time.compare(min_start_in_entries, daily_start_at) == :lt do
      min_start_in_entries
    else
      daily_start_at
    end
  end

  defp get_end_time_to_use(nil, daily_end_at) do
    daily_end_at
  end

  defp get_end_time_to_use(max_end_in_entries, daily_end_at) do
    if Time.compare(max_end_in_entries, daily_end_at) == :gt do
      max_end_in_entries
    else
      daily_end_at
    end
  end

  defp format_entries(activities, tenant) do
    activities
    |> Enum.map(fn activity ->
      activity.log_entries
    end)
    |> List.flatten()
    |> Enum.filter(fn entry ->
      entry.created_at |> DateTime.to_date() == Date.utc_today()
    end)
    |> Enum.sort_by(fn %{start_at: start_at, end_at: end_at} -> {start_at, end_at} end)
    |> Enum.map(fn x ->
      %{
        id: x.id,
        start_at: x.start_at |> format_timezone(tenant.timezone),
        end_at: get_end_time_in_entry(x.end_at) |> format_timezone(tenant.timezone),
        activity_id: x.activity_id,
        color_code:
          Enum.find(activities, fn activity ->
            activity.log_entries |> Enum.find(fn entry -> entry.start_at == x.start_at end)
          end).color_code
      }
    end)
  end

  defp get_end_time_in_entry(nil) do
    Time.utc_now()
  end

  defp get_end_time_in_entry(end_time) do
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

  defp get_time_range(log_entries) do
    log_entries =
      log_entries
      |> Enum.map(fn x ->
        %{
          start_at: x.start_at,
          end_at: get_end_time_in_entry(x.end_at)
        }
      end)

    Enum.reduce(log_entries, {nil, nil}, fn entry, {min_start, max_end} ->
      start_at = entry.start_at
      end_at = entry.end_at

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

  def handle_event("select_activity", %{"activity_id" => activity_id}, socket) do
    current_user = socket.assigns.current_user
    tenant = socket.assigns.tenant
    %{id: group_id} = _group = socket.assigns.group
    %{id: project_id} = _project = socket.assigns.project

    {:noreply,
     socket
     |> assign(
       :activities,
       activities(group_id, project_id, actor: current_user, tenant: tenant)
     )
     |> create_or_stop_log_entry(
       activity_id,
       tenant,
       current_user
     )}
  end

  def handle_event("select_group", %{"group_id" => id}, socket) do
    {:noreply,
     socket
     |> push_navigate(
       to:
         "/tenants/#{socket.assigns.tenant}/today?group_id=#{id}&project_id=#{socket.assigns.project.id}"
     )}
  end

  def handle_event("select_project", %{"project_id" => id}, socket) do
    {:noreply,
     socket
     |> push_navigate(
       to:
         "/tenants/#{socket.assigns.tenant}/today?group_id=#{socket.assigns.group.id}&project_id=#{id}"
     )}
  end

  defp create_or_stop_log_entry(socket, activity_id, tenant, user)
       when is_binary(activity_id) do
    {:ok, log_entries} =
      LogEntry.by_activity_today(%{activity_id: activity_id},
        actor: user,
        tenant: tenant
      )

    case Enum.find(log_entries, fn log_entry -> log_entry.end_at == nil end) do
      nil ->
        stop_any_active_log_entry(socket, tenant, user)
        create_log_entry(socket, activity_id)

      log_entry ->
        create_or_stop_log_entry(socket, log_entry, activity_id, actor: user, tenant: tenant)
    end
  end

  defp create_or_stop_log_entry(socket, log_entry, activity_id, opts) do
    if log_entry.activity_id == activity_id do
      stop_log_entry(socket, log_entry, opts)
    else
      stop_log_entry(socket, log_entry, opts)
      create_log_entry(socket, activity_id)
    end
  end

  defp stop_any_active_log_entry(socket, tenant, user) do
    {:ok, log_entries} = LogEntry.by_tenant(%{tenant_id: tenant.id}, actor: user, tenant: tenant)

    case Enum.find(log_entries, fn log_entry -> log_entry.end_at == nil end) do
      nil ->
        socket

      log_entry ->
        stop_log_entry(socket, log_entry, actor: user, tenant: tenant)
    end
  end

  defp create_log_entry(socket, activity_id) do
    tenant = socket.assigns.tenant
    user = socket.assigns.current_user

    if Ash.can?({LogEntry, :create}, user, tenant: tenant) do
      LogEntry.create(
        %{
          activity_id: activity_id,
          tenant_id: tenant.id,
          user_id: user.id,
          start_at: Time.utc_now()
        },
        actor: user,
        tenant: tenant
      )

      assign(socket, :active_activity_id, activity_id)
    else
      put_flash(socket, :error, gettext("You are not authorized to perform this action"))
    end
  end

  def stop_log_entry(socket, log_entry, opts) do
    if Ash.can?({log_entry, :update}, socket.assigns.current_user, tenant: socket.assigns.tenant) do
      LogEntry.update(log_entry, %{end_at: Time.utc_now()}, opts)

      assign(socket, :active_activity_id, nil)
    else
      put_flash(socket, :error, gettext("You are not authorized to perform this action"))
    end
  end

  defp latest_group_for_a_tenant(tenant_id) do
    case Group.by_tenant_id(%{tenant_id: tenant_id}) do
      {:ok, %{results: groups}} ->
        Enum.min_by(groups, & &1.created_at)

      _ ->
        %{
          id: ""
        }
    end
  end

  defp latest_project_for_a_tenant(tenant, current_user) do
    case Project.by_tenant_id(%{tenant_id: tenant.id}, actor: current_user, tenant: tenant) do
      {:ok, projects} ->
        Enum.min_by(projects, & &1.created_at)

      _ ->
        %{
          id: ""
        }
    end
  end

  defp groups_for_a_tenant(tenant_id) do
    case Group.by_tenant_id(%{tenant_id: tenant_id}) do
      {:ok, %{results: groups}} ->
        groups
        |> Enum.map(fn group -> {group.name, group.id} end)

      _ ->
        []
    end
  end

  defp projects_for_a_tenant(tenant, current_user) do
    case Project.by_tenant_id(%{tenant_id: tenant.id}, actor: current_user, tenant: tenant) do
      {:ok, projects} ->
        projects
        |> Enum.map(fn project -> {project.name, project.id} end)

      _ ->
        []
    end
  end
end
