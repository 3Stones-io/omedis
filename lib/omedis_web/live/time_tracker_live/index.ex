defmodule OmedisWeb.TimeTrackerLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Event
  alias Omedis.Accounts.User
  alias OmedisWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(%{current_organisation: nil} = assigns) do
    ~H"""
    """
  end

  def render(assigns) do
    ~H"""
    <div class="absolute top-3 right-[4rem] lg:right-[16rem] z-10 bg-black text-white shadow-lg rounded-lg">
      <%= if @current_activity do %>
        <.async_result :let={current_activity} assign={@current_activity}>
          <:loading>
            <div class="flex items-center gap-x-2 px-4 py-2">
              <div class="w-3 h-3 rounded-full animate-pulse bg-white"></div>
              00:00
            </div>
          </:loading>
          <div class="flex items-center gap-x-2 px-4 py-2">
            <div
              class="flex items-center gap-2 cursor-pointer"
              id="time-tracker-stop-event"
              phx-click={JS.push("stop_event", value: %{activity_id: current_activity.id})}
            >
              <div
                class="w-3 h-3 rounded-full animate-pulse"
                style={"background-color: #{current_activity.color_code}"}
              >
              </div>
              <%= @elapsed_time %>
            </div>
          </div>
        </.async_result>
      <% else %>
        <div class="relative">
          <button
            type="button"
            class="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-black rounded-lg hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
            phx-click={JS.toggle(to: "#time-tracker-activities-dropdown")}
          >
            <.icon name="hero-play-circle-solid" class="w-5 h-5" />
            <%= dgettext("time_tracker", "Start Timer") %>
          </button>

          <div
            id="time-tracker-activities-dropdown"
            class="hidden absolute right-0 mt-1 w-fit max-w-56 h-fit max-h-56 overflow-y-auto rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5"
            phx-click-away={JS.hide(to: "#time-tracker-activities-dropdown")}
            phx-hook="HideOnNavigate"
          >
            <%= if Enum.empty?(@activities) do %>
              <div class="pt-3 pb-1">
                <p class="text-black text-center">No activities to show</p>
              </div>
            <% else %>
              <div class="py-1" id="time-tracker-activities-dropdown-list" role="menu">
                <%= for activity <- @activities do %>
                  <button
                    phx-click="select_activity"
                    phx-value-activity_id={activity.id}
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900"
                    role="menuitem"
                  >
                    <div class="flex items-center gap-x-2">
                      <div
                        class="w-3 min-w-3 h-3 rounded-full"
                        style={"background-color: #{activity.color_code}"}
                      />
                      <span class="truncate">
                        <%= activity.name %>
                      </span>
                    </div>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      pubsub_topics_unique_id = session["pubsub_topics_unique_id"]

      :ok = Endpoint.subscribe("current_activity_#{pubsub_topics_unique_id}")

      :ok =
        Endpoint.subscribe("current_organisation_#{pubsub_topics_unique_id}")

      :ok =
        Endpoint.broadcast_from(
          self(),
          "time_tracker_live_view_#{pubsub_topics_unique_id}",
          "time_tracker_live_view_mounted",
          %{}
        )
    end

    {:ok,
     socket
     |> assign(:activities, [])
     |> assign(:current_activity, nil)
     |> assign(:current_organisation, nil)
     |> assign(:current_user, nil)
     |> assign(:current_user_id, session["current_user_id"])
     |> assign(:elapsed_time, "00:00")
     |> assign(:language, nil)
     |> assign(:load_more_activities_token, nil)
     |> assign(:timer_ref, nil), layout: false}
  end

  @impl true
  def handle_info(%Broadcast{event: "organisation_selected", payload: nil}, socket) do
    {:noreply, assign(socket, :current_organisation, nil)}
  end

  def handle_info(
        %Broadcast{
          event: "organisation_selected",
          payload: organisation
        },
        socket
      ) do
    current_user =
      User.by_id!(socket.assigns.current_user_id,
        authorize?: false,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:current_organisation, organisation)
     |> assign(:current_user, current_user)
     |> maybe_assign_activities()}
  end

  def handle_info(%Broadcast{event: "event_started", payload: activity}, socket) do
    {:noreply,
     assign_async(socket, :current_activity, fn ->
       {:ok, %{current_activity: activity}}
     end)}
  end

  def handle_info(%Broadcast{event: "event_stopped"}, socket) do
    {:noreply, assign(socket, :current_activity, nil)}
  end

  def handle_info(:tick, %{assigns: %{current_activity: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    elapsed_time =
      get_elapsed_time(socket.assigns.current_activity,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.current_organisation
      )

    {:noreply, assign(socket, :elapsed_time, elapsed_time)}
  end

  def handle_info({:stop_event, activity_id}, socket) do
    :ok =
      stop_event(activity_id,
        actor: socket.assigns.current_user,
        tenant: socket.assigns.current_organisation
      )

    {:noreply, socket}
  end

  defp get_elapsed_time(%Phoenix.LiveView.AsyncResult{result: activity}, opts) do
    get_elapsed_time(activity, opts)
  end

  defp get_elapsed_time(activity, opts) do
    do_get_elapsed_time(activity, opts)
  end

  defp do_get_elapsed_time(activity, opts) do
    {:ok, updated_activity} =
      Activity.by_id(activity.id, opts ++ [load: [:events]])

    case Enum.find(updated_activity.events, &is_nil(&1.dtend)) do
      nil ->
        "00:00"

      event ->
        now = Time.utc_now()
        seconds_diff = Time.diff(now, event.dtstart, :second)
        format_elapsed_time(seconds_diff)
    end
  end

  defp format_elapsed_time(seconds_diff) when seconds_diff < 60 do
    "00:#{String.pad_leading("#{seconds_diff}", 2, "0")}"
  end

  defp format_elapsed_time(seconds_diff) do
    minutes_diff = div(seconds_diff, 60)
    OmedisWeb.TimeTracking.minutes_to_hhmm(minutes_diff)
  end

  defp stop_event(activity_id, opts) do
    {:ok, events} =
      Event.by_activity_today(%{activity_id: activity_id}, opts)

    case Enum.find(events, fn event -> event.dtend == nil end) do
      nil ->
        :ok

      event ->
        do_stop_event(event, opts)

        :ok
    end
  end

  defp do_stop_event(event, opts) do
    if Ash.can?({event, :update}, opts[:actor], tenant: opts[:tenant]) do
      {:ok, _event} = Event.update(event, %{dtend: DateTime.utc_now()}, opts)
    end
  end

  defp start_timer do
    :timer.send_interval(1000, self(), :tick)
  end

  defp cancel_timer(nil), do: :ok

  defp cancel_timer(timer_ref) do
    {:ok, :cancel} = :timer.cancel(timer_ref)
    :ok
  end

  defp maybe_assign_activities(socket) do
    opts = build_opts(socket)

    {:ok, activities} = Activity.read(opts)

    socket
    |> assign_activities_and_token(activities)
    |> assign_current_activity(activities)
  end

  defp build_opts(socket) do
    base_opts = [
      actor: socket.assigns.current_user,
      tenant: socket.assigns.current_organisation,
      load: [:events]
    ]

    load_more_token = socket.assigns.load_more_activities_token

    if load_more_token do
      Keyword.put(base_opts, :page, after: load_more_token)
    else
      base_opts
    end
  end

  defp assign_activities_and_token(socket, activities) do
    load_more_activities_token =
      with last_activity when not is_nil(last_activity) <- List.last(activities) do
        last_activity.__metadata__.keyset
      end

    socket
    |> assign(:activities, activities)
    |> assign(:load_more_activities_token, load_more_activities_token)
  end

  defp assign_current_activity(socket, activities) do
    case get_current_activity(activities) do
      nil ->
        socket

      activity ->
        elapsed_time =
          get_elapsed_time(activity,
            actor: socket.assigns.current_user,
            tenant: socket.assigns.current_organisation
          )

        {:ok, timer_ref} = start_timer()

        socket
        |> assign(:elapsed_time, elapsed_time)
        |> assign_async(:current_activity, fn ->
          {:ok, %{current_activity: activity}}
        end)
        |> assign(:timer_ref, timer_ref)
    end
  end

  defp get_current_activity(activities) do
    activities
    |> Stream.map(fn activity ->
      if Enum.any?(activity.events, &is_nil(&1.dtend)) do
        activity
      end
    end)
    |> Stream.filter(&(&1 != nil))
    |> Enum.at(0)
  end

  @impl true
  def handle_event("select_activity", %{"activity_id" => activity_id}, socket) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.current_organisation]

    if Ash.can?({Event, :create}, opts[:actor], tenant: opts[:tenant]) do
      {:ok, timer_ref} = start_timer()

      {:noreply,
       socket
       |> assign_async(:current_activity, fn -> create_event(activity_id, opts) end)
       |> assign(:timer_ref, timer_ref)}
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         dgettext("time_tracker", "You are not authorized to perform this action")
       )}
    end
  end

  def handle_event("stop_event", %{"activity_id" => activity_id}, socket) do
    send(self(), {:stop_event, activity_id})
    :ok = cancel_timer(socket.assigns[:timer_ref])

    {:noreply,
     socket
     |> assign(:current_activity, nil)
     |> assign(:timer_ref, nil)}
  end

  def handle_event("load-more-activities", _params, socket) do
    {:noreply, maybe_assign_activities(socket)}
  end

  defp create_event(activity_id, opts) do
    {:ok, activity} = Activity.by_id(activity_id, opts ++ [load: [:events]])

    {:ok, _event} =
      Event.create(
        %{
          activity_id: activity_id,
          dtstart: DateTime.utc_now(),
          summary: activity.name,
          user_id: opts[:actor].id
        },
        opts
      )

    {:ok, %{current_activity: activity}}
  end
end
