defmodule OmedisWeb.PlaygroundLive.TimeTracking do
  use OmedisWeb, :live_view

  import OmedisWeb.CustomComponents

  alias OmedisWeb.ClientDoctorFormComponents

  @events [
    %{
      dtstart: ~T[09:00:00],
      dtend: ~T[10:30:00],
      activity_color: "#F43F5E",
      created_at: ~U[2025-02-16T09:00:00Z]
    },
    %{
      dtstart: ~T[11:00:00],
      dtend: ~T[12:30:00],
      activity_color: "#22C55E",
      created_at: ~U[2025-02-16T11:00:00Z]
    },
    %{
      dtstart: ~T[09:30:00],
      dtend: ~T[11:00:00],
      activity_color: "#6366F1",
      created_at: ~U[2025-02-17T09:30:00Z]
    },
    %{
      dtstart: ~T[13:00:00],
      dtend: ~T[14:30:00],
      activity_color: "#EAB308",
      created_at: ~U[2025-02-18T13:00:00Z]
    },
    %{
      dtstart: ~T[15:00:00],
      dtend: ~T[16:00:00],
      activity_color: "#A855F7",
      created_at: ~U[2025-02-18T15:00:00Z]
    }
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    favourite_activities = [
      %{
        id: 1,
        color: "#EF4444",
        title: "House keeping and grocery shopping",
        client_name: "Mrs Smith",
        is_favourite: true
      },
      %{
        id: 2,
        color: "#22C55E",
        title: "Routine Checkup",
        client_name: "Mr King",
        is_favourite: true
      },
      %{
        id: 3,
        color: "#A855F7",
        title: "Wound Dressing",
        client_name: "Mr King",
        is_favourite: true
      }
    ]

    activities = [
      %{
        id: 4,
        color: "#EF4444",
        title: "House keeping and grocery shopping",
        client_name: "Mrs Smith",
        is_favourite: false
      },
      %{
        id: 5,
        color: "#22C55E",
        title: "Routine Checkup",
        client_name: "Mr King",
        is_favourite: false
      },
      %{
        id: 6,
        color: "#A855F7",
        title: "Wound Dressing",
        client_name: "Mr King",
        is_favourite: false
      }
    ]

    projects = for i <- 1..10, do: "Project #{i}"

    fields = %{"activity" => "", "project" => ""}

    {:ok,
     socket
     |> assign(:activities, activities)
     |> assign(:favourite_activities, favourite_activities)
     |> assign(:form, to_form(fields))
     |> assign(:projects, projects)
     |> assign(:search_activities, [])
     |> assign(:begin_countdown, false)
     |> assign(:elapsed_time, "00:00:00")
     |> assign(:daily_start_at, "09:00")
     |> assign(:daily_end_at, "16:00")
     |> filter_events_by_date(DateTime.utc_now())}
  end

  @impl Phoenix.LiveView
  def handle_event("search-activity", %{"activity_query" => activity_query}, socket) do
    search_activities = search_activities(activity_query, socket)
    {:noreply, assign(socket, :search_activities, search_activities)}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", params, socket) do
    {:noreply,
     socket
     |> assign(:form, to_form(params))
     |> assign(:begin_countdown, true)}
  end

  def handle_event("stop-countdown", _params, socket) do
    {:noreply, assign(socket, :begin_countdown, false)}
  end

  def handle_event("fetch-events", %{"date" => date}, socket) do
    {:noreply, filter_events_by_date(socket, string_to_datetime_tuple(date))}
  end

  defp filter_events_by_date(socket, date) do
    target_date = DateTime.to_date(date)

    events =
      Enum.filter(@events, fn event ->
        Date.compare(DateTime.to_date(event.created_at), target_date) == :eq
      end)

    assign(socket, :events, events)
  end

  defp string_to_datetime_tuple(datetime_string) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_string)
    date = {datetime.year, datetime.month, datetime.day}
    time = {datetime.hour, datetime.minute, datetime.second}

    {date, time}
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
  end

  defp search_activities(activity_query, socket) do
    Enum.filter(
      socket.assigns.activities,
      &String.contains?(String.downcase(&1.title), String.downcase(activity_query))
    )
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section id="time-tracking-container">
      <.navbar
        breadcrumb_items={[
          {"Playground", ~p"/playground", false},
          {"Time Tracking", ~p"/playground/time-tracking", true}
        ]}
        activities={@activities}
        favourite_activities={@favourite_activities}
        search_activities={@search_activities}
      />

      <.form
        for={@form}
        phx-change="validate"
        phx-submit="save"
        class="text-sm time-tracking-form-grid px-2 py-4"
      >
        <ClientDoctorFormComponents.custom_input
          type="dropdown"
          field={@form[:project]}
          id="project-list"
          dropdown_prompt="Select project"
          dropdown_options={
            Enum.map(@projects, fn project ->
              Phoenix.HTML.raw(~s"
            <span class='px-4'>#{project}</span>
            ")
            end)
          }
          dropdown_prompt_class="project-btn text-sm"
          dropdown_list_class="absolute inset-x-[0.5rem] bg-white shadow-md rounded-lg border-[1px] border-time-tracker-dropdown-border z-[10000]"
        />

        <ClientDoctorFormComponents.custom_input
          type="dropdown"
          field={@form[:activity]}
          id="activity-list"
          dropdown_prompt="Select activity"
          dropdown_options={
            Enum.map(@activities, fn activity ->
              Phoenix.HTML.raw(~s"
              <span class='flex items-center gap-2 px-4'>
               <span>#{activity_color_icon(activity)}</span>
                <span>#{activity.title}</span>
              </span>
            ")
            end)
          }
          has_dropdown_slot={true}
          dropdown_prompt_class="activity-btn text-sm"
          dropdown_list_class="absolute inset-x-[0.5rem] bg-white shadow-md rounded-lg border-[1px] border-time-tracker-dropdown-border z-[10000]"
        />

        <button
          :if={!@begin_countdown}
          type="submit"
          class={[
            "btn px-4 py-2 rounded-md text-base mt-2",
            (input_value(@form, :project) == "" || input_value(@form, :activity) == "") &&
              "bg-time-tracker-start-btn-disabled-bg text-time-tracker-start-btn-disabled-txt cursor-not-allowed",
            input_value(@form, :project) != "" && input_value(@form, :activity) != "" &&
              "bg-time-tracker-start-btn-bg text-white cursor-pointer"
          ]}
          disabled={input_value(@form, :project) == "" || input_value(@form, :activity) == ""}
          title={
            if input_value(@form, :project) == "" || input_value(@form, :activity) == "",
              do: "Please select a project and activity"
          }
        >
          <span>
            Start timer <.icon name="hero-play-circle-solid" class="w-5 h-5" />
          </span>
        </button>

        <button
          :if={@begin_countdown}
          type="button"
          class="btn px-4 py-2  mt-2 rounded-md text-base bg-time-tracker-countdown-btn-bg text-white cursor-pointer flex items-center justify-center gap-2"
          phx-click="stop-countdown"
        >
          <span class="h-4 w-4 bg-time-tracker-start-btn-bg rounded-full inline-block border-[2px] border-white animate-pulse">
          </span>
          <span>{@elapsed_time}</span>
          <.icon name="hero-stop-circle-solid" class="w-5 h-5" />
        </button>
      </.form>

      <div class="calendar-container px-2">
        <div
          class="text-timeline-calendar-btn-txt bg-timeline-calendar-btn-bg py-4 px-4 mb-[-2px] z-[100] rounded-t-xl flex items-center justify-between"
          id="timeline-calendar-date-selector"
          phx-hook="TimelineCalendarDateSelector"
        >
          <button id="timeline-calendar-date-selector-previous">
            <.icon name="hero-chevron-left-solid" class="w-5 h-5" />
          </button>
          <p id="timeline-calendar-date-selector-date"></p>
          <button id="timeline-calendar-date-selector-next">
            <.icon name="hero-chevron-right-solid" class="w-5 h-5" />
          </button>
        </div>

        <div
          id="timeline-calendar"
          phx-hook="TimelineCalendar"
          data-daily-start-at={@daily_start_at}
          data-daily-end-at={@daily_end_at}
          data-events={Jason.encode!(@events)}
          class="w-full max-w-2xl min-h-[70svh]"
        >
        </div>
      </div>
    </section>
    """
  end

  defp activity_color_icon(activity) do
    ~s"""
     <svg width='20' height='20' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'>
      <path d='M20 10C20 15.5228 15.5228 20 10 20C4.47715 20 0 15.5228 0 10C0 4.47715 4.47715 0 10 0C15.5228 0 20 4.47715 20 10ZM1.9775 10C1.9775 14.4307 5.5693 18.0225 10 18.0225C14.4307 18.0225 18.0225 14.4307 18.0225 10C18.0225 5.5693 14.4307 1.9775 10 1.9775C5.5693 1.9775 1.9775 5.5693 1.9775 10Z'
        fill='#{activity.color}'
      />
      <circle cx='10' cy='10' r='3' fill='#{activity.color}' />
    </svg>
    """
  end
end
