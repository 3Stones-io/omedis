defmodule OmedisWeb.CustomComponents do
  @moduledoc false

  use OmedisWeb, :html

  alias OmedisWeb.Components.Icons

  attr :breadcrumb_items, :list, default: []
  attr :company_name, :string, default: "Omedis"
  attr :language, :string, default: "en"
  attr :activities, :any, default: []
  attr :favourite_activities, :any, default: []
  attr :search_activities, :list, default: []

  def navbar(assigns) do
    ~H"""
    <div class="relative">
      <nav class="font-openSans relative">
        <div class="nav-primary px-3 py-5 border-y-[1.5px] border-y-section-border bg-bg-secondary">
          <div class="w-full flex justify-between items-center">
            <div class="flex gap-3">
              <button
                class="inline-block border border-btn-border rounded-lg flex items-center justify-center px-2 my-[.15em]"
                phx-click={show_mobile_menu()}
              >
                <.icon name="hero-bars-3" class="w-6 h-6 text-icons-txt-secondary" />
              </button>
              <div>
                <h2 class="font-semibold text-txt-primary">{@company_name}</h2>
                <.client_doctor_breadcrumb items={@breadcrumb_items} />
              </div>
            </div>
            <div class="flex items-center border border-btn-border text-txt-secondary rounded-lg">
              <button class="h-full w-full py-2 px-3 border-r border-btn-border">
                <.icon name="hero-clock" class="w-5 h-5" />
              </button>
              <button class="h-full w-full p-2" phx-click={toggle_time_tracking_component()}>
                <.icon
                  name="hero-chevron-down"
                  class="w-5 h-5 toggle-time-tracking-component-chevron"
                />
              </button>
            </div>
          </div>
        </div>
        <.mobile_menu />
      </nav>

      <.time_tracking_component
        activities={@activities}
        favourite_activities={@favourite_activities}
        search_activities={@search_activities}
      />
    </div>
    """
  end

  defp mobile_menu(assigns) do
    ~H"""
    <nav
      class="sidebar-nav bg-bg-primary min-h-screen w-[70%] shadow-md rounded-r-lg absolute top-0 left-0 z-[10000] px-4 hidden"
      id="mobile-menu"
      phx-click-away={hide_mobile_menu()}
    >
      <div class="flex justify-between items-center py-6">
        <div class="logo flex items-center gap-2">
          <img src={~p"/images/omedis_logo.png"} class="h-10 object-contain" />
        </div>
        <button phx-click={hide_mobile_menu()}>
          <.icon name="hero-x-mark" class="w-6 h-6 text-icons-txt-secondary" />
        </button>
      </div>

      <ul class="grid gap-y-4">
        <li :for={{icon, label, path} <- mobile_menu_items()} class="py-4">
          <.link navigate={path} class="flex items-center gap-4">
            <.icon name={icon} class="w-6 h-6 text-icons-txt-secondary" />
            <span class="text-txt-secondary">{label}</span>
          </.link>
        </li>
      </ul>
    </nav>
    """
  end

  defp client_doctor_breadcrumb(assigns) do
    assigns =
      if(length(assigns.items) >= 2,
        do: assign_breadcrumb_items(assigns, Enum.take(assigns.items, -2)),
        else: assign_breadcrumb_items(assigns, assigns.items)
      )

    ~H"""
    <nav
      :if={!Enum.empty?(@breadcrumb_items)}
      class="flex items-center"
      aria-label={dgettext("navigation", "Navigation Breadcrumb")}
    >
      <ul class="flex items-center gap-1">
        <.breadcrumb_item
          :for={{label, path, is_current} <- @breadcrumb_items}
          label={label}
          path={path}
          is_current={is_current}
        />
      </ul>
    </nav>
    """
  end

  defp assign_breadcrumb_items(assigns, items) do
    assign(assigns, :breadcrumb_items, items)
  end

  defp breadcrumb_item(assigns) do
    ~H"""
    <li class="flex items-center">
      <.link navigate={@path} class="flex gap-x-1 text-xs font-medium">
        <span class={[
          @is_current && "text-txt-primary",
          !@is_current && "text-txt-secondary"
        ]}>
          {@label}
        </span>
        <span :if={!@is_current} class="text-txt-secondary"> / </span>
      </.link>
    </li>
    """
  end

  defp mobile_menu_items do
    [
      {"hero-clock", "Time Tracker", ~p"/today"},
      {"hero-user", "Clients", ~p"/"},
      {"hero-user", "Doctors", ~p"/"},
      {"hero-building-office", "Organisations", ~p"/"},
      {"hero-user-group", "Team", ~p"/"},
      {"hero-folder", "Project", ~p"/"},
      {"hero-calendar", "Calendar", ~p"/"},
      {"hero-document", "Documents", ~p"/"},
      {"hero-chart-bar", "Report", ~p"/"}
    ]
  end

  defp show_mobile_menu(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-menu")
    |> JS.add_class("blur-[4px]", to: ".nav-primary")
    # TODO: Replace with container for actual elements
    |> JS.add_class("blur-[4px]", to: ".content")
  end

  defp hide_mobile_menu(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-menu")
    |> JS.remove_class("blur-[4px]", to: ".nav-primary")
    # TODO: Replace with container for actual elements
    |> JS.remove_class("blur-[4px]", to: ".content")
  end

  defp time_tracking_component(assigns) do
    ~H"""
    <div
      class={[
        "font-openSans w-[90%] absolute right-2 -translate-x-2 top-[80%] z-[10000] hidden",
        "border-[1px] border-time-tracking-container-border rounded-lg pt-6 bg-time-tracking-container-bg shadow-sm shadow-time-tracking-container-shadow"
      ]}
      id="time-tracking-component"
      phx-click-away={toggle_time_tracking_component()}
    >
      <div class={[
        "search-input-container px-2 mx-4 border-[1px] border-form-input-border rounded-lg bg-inherit",
        "grid grid-cols-[1em_1fr] items-center "
      ]}>
        <.icon
          name="hero-magnifying-glass"
          class="w-5 h-5 inline-block text-form-txt-primary row-span-full col-span-full"
        />
        <input
          type="text"
          placeholder="Search project or activity"
          class="border-none focus:ring-0 row-span-full col-span-full mx-4 search-input"
          id="time-tracking-search"
          phx-hook="SearchActivityInput"
        />
      </div>

      <.activities_list
        condition={Enum.empty?(@activities) && Enum.empty?(@favourite_activities)}
        empty_message="No previous activity yet"
        id="activities-list"
      >
        <.timetracking_list_title
          :if={!Enum.empty?(@favourite_activities)}
          title="Favourite Activities"
          list_id="favourite-activities-list"
        />

        <.timetracking_list_items
          :if={!Enum.empty?(@favourite_activities)}
          activities={@favourite_activities}
          list_id="favourite-activities-list"
          class="hidden"
        />

        <.timetracking_list_title
          :if={!Enum.empty?(@activities)}
          title="Previously Tracked"
          list_id="previously-tracked-list"
        />

        <.timetracking_list_items
          :if={!Enum.empty?(@activities)}
          activities={@activities}
          list_id="previously-tracked-list"
          class="hidden"
        />
      </.activities_list>

      <.activities_list
        condition={Enum.empty?(@search_activities)}
        empty_message="No activities found"
        id="search-activities-list-container"
        class="hidden"
      >
        <.timetracking_list_items
          :if={!Enum.empty?(@search_activities)}
          activities={@search_activities}
          list_id="search-activities-list"
        />
      </.activities_list>

      <div class="border-t border-form-input-border">
        <button type="button" class="text-md flex items-center p-4 gap-2 w-full">
          <.icon name="hero-plus-circle" class="w-6 h-6 text-form-radio-checked-primary" />
          <span class="text-form-radio-checked-primary">Select new project and activity</span>
        </button>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :condition, :boolean, default: true
  attr :empty_message, :string
  attr :id, :string

  slot :inner_block

  defp activities_list(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "w-full grid items-center py-2",
        @class
      ]}
    >
      <div
        :if={@condition}
        class="flex text-form-txt-primary py-6 items-center justify-center"
        id={"#{@id}-empty"}
      >
        <p>
          {@empty_message}
        </p>
      </div>

      <div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp timetracking_list_title(assigns) do
    ~H"""
    <button
      type="button"
      class="flex items-center justify-between w-full px-4 py-2"
      phx-click={toggle_activities_list(@list_id)}
    >
      <span class="text-form-txt-primary">{@title}</span>
      <span class="flex items-center gap-2" id={@list_id <> "-chevron"}>
        <.icon name="hero-chevron-down" class="w-6 h-6 text-form-txt-primary" />
      </span>
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :activities, :any
  attr :list_id, :string

  defp timetracking_list_items(assigns) do
    ~H"""
    <div
      class={[
        "text-form-txt-secondary text-sm p-4 bg-activity-list-bg grid gap-y-4",
        @class
      ]}
      role="list"
      id={@list_id}
    >
      <div
        :for={activity <- @activities}
        class="grid grid-cols-[1.5em_1fr_1em]"
        id={"activity-#{activity.id}"}
        role="listitem"
      >
        <div><Icons.circle_with_dot fill={activity.color} /></div>
        <p class="line-clamp-1 ml-1 font-0">
          <span>{activity.title}</span><span> - {activity.client_name}</span>
        </p>

        <div class="ml-auto">
          <.icon
            name={if(activity.is_favourite, do: "hero-star-solid", else: "hero-star")}
            class={[
              "w-5 h-4",
              activity.is_favourite && "text-yellow-500",
              !activity.is_favourite && "text-form-txt-primary"
            ]}
          />
        </div>
      </div>
    </div>
    """
  end

  defp toggle_activities_list(list_id, js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden", to: "##{list_id}", transition: "ease-in-out duration-300")
    |> JS.toggle_class("rotate-180",
      to: "##{list_id}-chevron",
      transition: "ease-in-out duration-300"
    )
  end

  defp toggle_time_tracking_component(js \\ %JS{}) do
    js
    |> JS.toggle_class("hidden",
      to: "#time-tracking-component",
      transition: "ease-in-out duration-300"
    )
    |> JS.toggle_class("rotate-180",
      to: ".toggle-time-tracking-component-chevron",
      transition: "ease-in-out duration-300"
    )
  end
end
