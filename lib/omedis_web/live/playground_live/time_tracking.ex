defmodule OmedisWeb.PlaygroundLive.TimeTracking do
  use OmedisWeb, :live_view

  import OmedisWeb.CustomComponents

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

    {:ok,
     socket
     |> assign(:activities, activities)
     |> assign(:favourite_activities, favourite_activities)
     |> assign(:search_activities, [])}
  end

  @impl Phoenix.LiveView
  def handle_event("search-activity", %{"activity_query" => activity_query}, socket) do
    search_activities = search_activities(activity_query, socket)
    {:noreply, assign(socket, :search_activities, search_activities)}
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
    </section>
    """
  end
end
