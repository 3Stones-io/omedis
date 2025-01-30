defmodule OmedisWeb.ClientDoctorFormComponents do
  @moduledoc false

  use OmedisWeb, :html

  attr :breadcrumb_items, :list, default: []
  attr :company_name, :string, default: "Omedis"
  attr :language, :string, default: "en"

  def navbar(assigns) do
    ~H"""
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
            <button class="h-full w-full p-2">
              <.icon name="hero-chevron-down" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <.mobile_menu />
    </nav>
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
          <div class="bg-icons-txt-secondary h-8 w-8 rounded-lg"></div>
          <p class="uppercase font-semibold text-xl text-txt-primary">Company</p>
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
end
