defmodule OmedisWeb.TenantLive.Today do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.LogEntry
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dashboard_component
        categories={@categories}
        start_at={@start_at}
        end_at={@end_at}
        log_entries={@log_entries}
        current_time={@current_time}
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    tenant = Tenant.by_slug!(slug)

    {min_start_in_entries, max_end_in_entries} =
      get_time_range(LogEntry.by_tenant_today!(%{tenant_id: tenant.id}))

    start_at = get_start_time_to_use(min_start_in_entries, tenant.daily_start_at)

    end_at = get_end_time_to_use(max_end_in_entries, tenant.daily_end_at)

    update_categories_and_current_time_every_minute()

    categories = categories(tenant.id)

    log_entries = format_entries(categories)

    {:noreply,
     socket
     |> assign(:page_title, "Today")
     |> assign(:tenant, tenant)
     |> assign(:value, 0)
     |> assign(:start_at, start_at)
     |> assign(:end_at, end_at)
     |> assign(:log_entries, log_entries)
     |> assign(:current_time, Time.utc_now())
     |> assign(:categories, categories)}
  end

  @impl true
  def handle_info(:update_categories_and_current_time, socket) do
    tenant = socket.assigns.tenant

    categories = categories(tenant.id)

    log_entries =
      format_entries(categories)

    {:noreply,
     socket
     |> assign(:categories, categories)
     |> assign(:log_entries, log_entries)
     |> assign(:value, socket.assigns.value + 1)
     |> assign(:current_time, Time.utc_now())}
  end

  defp update_categories_and_current_time_every_minute do
    :timer.send_interval(60_000, self(), :update_categories_and_current_time)
  end

  defp get_start_time_to_use(nil, tenant_daily_start_at) do
    tenant_daily_start_at
  end

  defp get_start_time_to_use(min_start_in_entries, tenant_daily_start_at) do
    if Time.compare(min_start_in_entries, tenant_daily_start_at) == :lt do
      min_start_in_entries
    else
      tenant_daily_start_at
    end
  end

  defp get_end_time_to_use(nil, tenant_daily_end_at) do
    tenant_daily_end_at
  end

  defp get_end_time_to_use(max_end_in_entries, tenant_daily_end_at) do
    if Time.compare(max_end_in_entries, tenant_daily_end_at) == :gt do
      max_end_in_entries
    else
      tenant_daily_end_at
    end
  end

  defp format_entries(categories) do
    categories
    |> Enum.map(fn category ->
      category.log_entries
    end)
    |> List.flatten()
    |> Enum.filter(fn entry ->
      entry.created_at |> DateTime.to_date() == Date.utc_today()
    end)
    |> Enum.sort_by(fn %{start_at: start_at, end_at: end_at} -> {start_at, end_at} end)
    |> Enum.map(fn x ->
      %{
        id: x.id,
        start_at: x.start_at,
        end_at: get_end_time_in_entry(x.end_at),
        category_id: x.log_category_id,
        color_code:
          Enum.find(categories, fn category ->
            category.log_entries |> Enum.find(fn entry -> entry.start_at == x.start_at end)
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

  defp categories(tenant_id) do
    case LogCategory.by_tenant_id(%{tenant_id: tenant_id}) do
      {:ok, categories} ->
        categories

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

  @impl true

  def handle_event("select_log_category", %{"log_category_id" => log_category_id}, socket) do
    create_or_stop_log_entry(
      log_category_id,
      socket.assigns.tenant.id,
      socket.assigns.current_user.id
    )

    {:noreply,
     socket
     |> assign(:categories, categories(socket.assigns.tenant.id))}
  end

  defp create_or_stop_log_entry(log_category_id, tenant_id, user_id) do
    {:ok, log_entries} = LogEntry.by_log_category_today(%{log_category_id: log_category_id})

    case Enum.find(log_entries, fn log_entry -> log_entry.end_at == nil end) do
      nil ->
        stop_any_active_log_entry(tenant_id)
        create_log_entry(log_category_id, tenant_id, user_id)

      log_entry ->
        create_or_stop_log_entry(log_entry, log_category_id)
    end
  end

  defp create_or_stop_log_entry(log_entry, log_category_id) do
    if log_entry.log_category_id == log_category_id do
      stop_log_entry(log_entry)
    else
      stop_log_entry(log_entry)
      create_log_entry(log_category_id, log_entry.tenant_id, log_entry.user_id)
    end
  end

  defp stop_any_active_log_entry(tenant_id) do
    {:ok, log_entries} = LogEntry.by_tenant(%{tenant_id: tenant_id})

    case Enum.find(log_entries, fn log_entry -> log_entry.end_at == nil end) do
      nil ->
        :ok

      log_entry ->
        stop_log_entry(log_entry)
    end
  end

  defp create_log_entry(log_category_id, tenant_id, user_id) do
    LogEntry.create(%{
      log_category_id: log_category_id,
      tenant_id: tenant_id,
      user_id: user_id,
      start_at: Time.utc_now()
    })
  end

  def stop_log_entry(log_entry) do
    LogEntry.update(log_entry, %{end_at: Time.utc_now()})
  end
end
