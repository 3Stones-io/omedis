defmodule OmedisWeb.PlaygroundLive.TimeTracking do
  use OmedisWeb, :live_view

  import OmedisWeb.CustomComponents

  alias OmedisWeb.ClientDoctorFormComponents
  alias OmedisWeb.TimeTracking

  @events [
    %{
      id: 1,
      dtstart: ~T[09:00:00],
      dtend: ~T[10:30:00],
      activity_color: "#F43F5E",
      client_title: "Mrs",
      client_first_name: "Fitcher",
      client_last_name: "Smith",
      created_at: ~U[2025-02-15T09:00:00Z],
      activity_title: "House keeping and grocery shopping"
    },
    %{
      id: 2,
      dtstart: ~T[11:00:00],
      dtend: ~T[12:30:00],
      activity_color: "#22C55E",
      client_title: "Mr",
      client_first_name: "Lion",
      client_last_name: "King",
      created_at: ~U[2025-02-16T11:00:00Z],
      activity_title: "Routine Checkup"
    },
    %{
      id: 3,
      dtstart: ~T[09:30:00],
      dtend: ~T[11:00:00],
      activity_color: "#6366F1",
      client_title: "Mr",
      client_first_name: "Lion",
      client_last_name: "King",
      created_at: ~U[2025-02-16T09:30:00Z],
      activity_title: "Wound Dressing"
    },
    %{
      id: 4,
      dtstart: ~T[13:00:00],
      dtend: ~T[14:30:00],
      activity_color: "#EAB308",
      client_title: "Mr",
      client_first_name: "Lion",
      client_last_name: "King",
      created_at: DateTime.utc_now(),
      activity_title: "Wound Dressing"
    },
    %{
      id: 5,
      dtstart: ~T[15:00:00],
      dtend: ~T[15:45:00],
      activity_color: "#A855F7",
      client_title: "Mrs",
      client_first_name: "Fitcher",
      client_last_name: "Smith",
      created_at: DateTime.utc_now(),
      activity_title: "House keeping and grocery shopping"
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
     |> assign(:total_time_spent, "00:00:00")
     |> filter_events_by_date(DateTime.utc_now())
     |> assign(:show_delete_confirmation?, false)
     |> assign(:show_edit_menu?, false)
     |> total_time_spent()}
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

  def handle_event("delete-entry", %{"id" => id}, socket) do
    events =
      Enum.filter(socket.assigns.events, &(&1.id != id))

    {:noreply,
     socket
     |> assign(:events, events)
     |> assign(:show_delete_confirmation?, true)}
  end

  def handle_event("edit-entry", _params, socket) do
    {:noreply, assign(socket, :show_edit_menu?, true)}
  end

  def handle_event("stop-countdown", _params, socket) do
    {:noreply, assign(socket, :begin_countdown, false)}
  end

  def handle_event("hide-delete-confirmation", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirmation?, false)}
  end

  defp total_time_spent(socket) do
    total_time_spent =
      socket.assigns.events
      |> Enum.map(fn event ->
        Time.diff(event.dtend, event.dtstart, :second)
      end)
      |> Enum.reduce(0, fn time_diff, acc -> acc + time_diff end)
      |> format_total_time()

    assign(socket, :total_time_spent, total_time_spent)
  end

  defp format_total_time(total_time_spent) when total_time_spent < 60 do
    "#{total_time_spent}sec"
  end

  defp format_total_time(total_time_spent) when total_time_spent < 3600 do
    minutes = div(total_time_spent, 60)
    "#{minutes}min"
  end

  defp format_total_time(total_time_spent) do
    hours = div(total_time_spent, 3600)
    remaining_minutes = div(rem(total_time_spent, 3600), 60)

    "#{hours}h #{remaining_minutes}min"
  end

  defp filter_events_by_date(socket, date) do
    events =
      Enum.filter(@events, fn event ->
        Date.compare(DateTime.to_date(event.created_at), date) == :eq
      end)

    assign(socket, :events, events)
  end

  defp calculate_event_duration(event) do
    event.dtend
    |> Time.diff(event.dtstart, :second)
    |> format_total_time()
  end

  defp format_dtstart_dtend(time) do
    time_string = "#{Time.to_string(time)}"

    String.slice(time_string, 0..4)
  end

  defp search_activities(activity_query, socket) do
    Enum.filter(
      socket.assigns.activities,
      &String.contains?(String.downcase(&1.title), String.downcase(activity_query))
    )
  end

  # Todo: Use a stream in place of the list to list events
  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section id="time-tracking-container" class="px-2">
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
        class="text-sm time-tracking-form-grid py-4 px-2"
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

      <div class="daily-report text-sm relative">
        <h4 class="bg-time-tracking-daily-report-header-bg px-2 py-4 rounded-t-lg flex items-center justify-between">
          <span>Daily Report</span>
          <span class="font-semibold">{@total_time_spent}</span>
        </h4>

        <ul>
          <TimeTracking.daily_summary_list_item
            :for={event <- @events}
            dtend={format_dtstart_dtend(event.dtend)}
            dtstart={format_dtstart_dtend(event.dtstart)}
            event_duration={calculate_event_duration(event)}
            event={event}
          />
        </ul>

        <p
          :if={@show_delete_confirmation?}
          class={[
            "bg-white shadow-sm rounded-lg border-[1px] border-time-tracking-entry-delete-confirmation-border px-4",
            "absolute inset-x-12 top-16 z-1000",
            "flex items-center justify-between"
          ]}
          id="delete-confirmation"
          phx-click-away={JS.hide(to: "#delete-confirmation")}
          phx-hook="EventDeleteConfirmation"
        >
          <span class="inline-block grow text-time-tracking-entry-delete-confirmation-txt border-r border-time-tracking-entry-delete-confirmation-border py-3">
            Entry has been deleted
          </span>
          <button class="pl-2 text-time-tracking-entry-delete-confirmation-undo-btn">
            Undo
          </button>
        </p>

        <div :if={@show_edit_menu?}></div>
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
