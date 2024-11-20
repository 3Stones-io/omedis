defmodule OmedisWeb.TimeTrackerLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Event
  alias Omedis.Accounts.User

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
              (00:00)
            </div>
          </:loading>
          <div class="flex items-center gap-x-2 px-4 py-2">
            <div
              class="flex items-center gap-2 cursor-pointer"
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
            phx-click={JS.toggle(to: "#activity-dropdown")}
          >
            <.icon name="hero-play-circle-solid" class="w-5 h-5" />
            <%= gettext("Start Timer") %>
          </button>

          <div
            id="activity-dropdown"
            class="hidden absolute right-0 mt-1 w-fit max-w-56 h-fit max-h-56 overflow-y-auto rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5"
          >
            <%= if Enum.empty?(@activities) do %>
              <div class="pt-3 pb-1">
                <p class="text-black text-center">No activities to show</p>
              </div>
            <% else %>
              <div class="py-1" role="menu">
                <%= for activity <- @activities do %>
                  <button
                    phx-click="select_activity"
                    phx-value-activity-id={activity.id}
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
      :ok = Phoenix.PubSub.subscribe(Omedis.PubSub, "current_activity_#{pubsub_topics_unique_id}")

      :ok =
        Phoenix.PubSub.subscribe(Omedis.PubSub, "current_organisation_#{pubsub_topics_unique_id}")

      :ok =
        Phoenix.PubSub.broadcast_from(
          Omedis.PubSub,
          self(),
          "time_tracker_live_view_#{pubsub_topics_unique_id}",
          {:time_tracker_live_view, :mounted}
        )
    end

    {:ok,
     socket
     |> assign(:activities, [])
     |> assign(:current_activity, nil)
     |> assign(:current_organisation, nil)
     |> assign(:current_user, nil)
     |> assign(:current_user_id, session["current_user_id"])
     |> assign(:elapsed_time, "(00:00)")
     |> assign(:language, nil)
     |> assign(:load_more_activities_token, nil)
     |> assign(:timer_ref, nil), layout: false}
  end

  @impl true
  def handle_info({:organisation_selected, nil}, socket) do
    {:noreply, assign(socket, :current_organisation, nil)}
  end

  def handle_info({:organisation_selected, organisation}, socket) do
    current_user =
      User.by_id!(socket.assigns.current_user_id,
        authorize?: false,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:current_organisation, organisation)
     |> assign(:current_user, current_user)
     |> maybe_assign_current_activity_and_list_activities()}
  end

  def handle_info({:event_started, activity}, socket) do
    {:noreply,
     assign_async(socket, :current_activity, fn ->
       {:ok, %{current_activity: activity}}
     end)}
  end

  def handle_info({:event_stopped, _}, socket) do
    {:noreply, assign(socket, :current_activity, nil)}
  end

  def handle_info(:tick, %{assigns: %{current_activity: nil}} = socket) do
    {:noreply, assign(socket, :timer_ref, nil)}
  end

  def handle_info(:tick, socket) do
    elapsed_time = get_elapsed_time(socket.assigns.current_activity)

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

  defp get_elapsed_time(%Phoenix.LiveView.AsyncResult{result: activity}) do
    do_get_elapsed_time(activity)
  end

  defp get_elapsed_time(activity) do
    do_get_elapsed_time(activity)
  end

  defp do_get_elapsed_time(activity) do
    case Enum.find(activity.events, &is_nil(&1.dtend)) do
      nil ->
        "(00:00)"

      event ->
        Time.utc_now()
        |> Time.diff(event.dtstart, :minute)
        |> OmedisWeb.TimeTracking.minutes_to_hhmm()
    end
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

  defp maybe_assign_current_activity_and_list_activities(socket) do
    load_more_token = socket.assigns.load_more_activities_token
    opts = build_opts(socket, load_more_token)

    {:ok, %{results: activities}} = do_list_activities(opts)

    socket
    |> assign_activities_and_token(activities)
    |> assign_current_activity(activities)
  end

  defp build_opts(socket, load_more_token) do
    base_opts = [
      actor: socket.assigns.current_user,
      tenant: socket.assigns.current_organisation,
      load: [:events]
    ]

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

  defp do_list_activities(opts) do
    Activity.list_cursor_paginated(opts)
  end

  defp assign_current_activity(socket, activities) do
    case get_current_activity(activities) do
      nil ->
        socket

      activity ->
        elapsed_time = get_elapsed_time(activity)

        socket
        |> assign(:elapsed_time, elapsed_time)
        |> assign_async(:current_activity, fn ->
          {:ok, %{current_activity: activity}}
        end)
        |> then(fn socket ->
          {:ok, timer_ref} = start_timer()

          assign(socket, :timer_ref, timer_ref)
        end)
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
  def handle_event("select_activity", %{"activity-id" => activity_id}, socket) do
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.current_organisation]

    if Ash.can?({Event, :create}, opts) do
      {:noreply,
       socket
       |> assign_async(:current_activity, fn -> create_event(activity_id, opts) end)
       |> then(fn socket ->
         {:ok, timer_ref} = start_timer()

         assign(socket, :timer_ref, timer_ref)
       end)}
    else
      put_flash(socket, :error, gettext("You are not authorized to perform this action"))
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
    {:noreply, maybe_assign_current_activity_and_list_activities(socket)}
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
