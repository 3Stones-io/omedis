defmodule OmedisWeb.GeneralComponents do
  @moduledoc """
  Provides general components for the application.
  """
  use OmedisWeb, :verified_routes
  use Phoenix.Component
  use Gettext, backend: OmedisWeb.Gettext

  alias Phoenix.LiveView.JS

  def breadcrumb(assigns) do
    ~H"""
    <div class="lg:hidden -mt-10 mb-3 -mx-6 lg:-mx-8">
      <.mobile_breadcrumb items={assigns.items} language={@language} />
    </div>
    <div class="hidden lg:block -mt-10 mb-3 -mx-6 lg:-mx-8">
      <.desktop_breadcrumb items={assigns.items} language={@language} />
    </div>
    """
  end

  def desktop_breadcrumb(assigns) do
    ~H"""
    <nav
      class="flex pl-6 lg:pl-8 border-b border-gray-200 bg-white"
      aria-label={dgettext("navigation", "Navigation Breadcrumb")}
    >
      <ol role="list" class="flex w-full max-w-screen-xl space-x-4">
        <%= for {label, path, is_current} <- @items do %>
          <.render_breadcrumb_item label={label} path={path} is_current={is_current} />
        <% end %>
      </ol>
    </nav>
    """
  end

  def mobile_breadcrumb(assigns) do
    items_count = length(assigns.items)
    show_full_breadcrumb = items_count <= 4

    assigns = assign(assigns, :show_full_breadcrumb, show_full_breadcrumb)

    ~H"""
    <nav
      class="flex pl-6 lg:pl-8 border-b border-gray-200 bg-white"
      aria-label={dgettext("navigation", "Navigation Breadcrumb")}
    >
      <ol role="list" class="mx-auto flex w-full max-w-screen-xl space-x-4">
        <%= if @show_full_breadcrumb do %>
          <%= for {label, path, is_current} <- @items do %>
            <.render_breadcrumb_item label={label} path={path} is_current={is_current} />
          <% end %>
        <% else %>
          <%= for {label, path, is_current} <- Enum.take(@items, 2) do %>
            <.render_breadcrumb_item label={label} path={path} is_current={is_current} />
          <% end %>
          <li class="flex items-center pb-3 text-gray-500 text-2xl">...</li>
          <%= for {label, path, is_current} <- Enum.take(@items, -2) do %>
            <.render_breadcrumb_item label={label} path={path} is_current={is_current} />
          <% end %>
        <% end %>
      </ol>
    </nav>
    """
  end

  def render_breadcrumb_item(assigns) do
    ~H"""
    <li class="flex">
      <div class="flex items-center">
        <%= if @label === "Home" do %>
          <div class="flex items-center">
            <%= if @is_current do %>
              <div class="text-sm font-medium text-gray-700" aria-current="page">
                <.home_icon />
              </div>
            <% else %>
              <a href={@path} class="text-sm font-medium text-gray-500 hover:text-gray-900">
                <.home_icon />
              </a>
            <% end %>
          </div>
        <% else %>
          <%= if @is_current do %>
            <p class="truncate text-sm font-medium text-gray-900" aria-current="page">
              <%= @label %>
            </p>
          <% else %>
            <a href={@path} class="truncate text-sm font-medium text-gray-500 hover:text-gray-900">
              <%= @label %>
            </a>
          <% end %>
        <% end %>
        <%= if not @is_current do %>
          <svg
            class="h-full w-6 flex-shrink-0 text-gray-200"
            viewBox="0 0 24 44"
            preserveAspectRatio="none"
            fill="currentColor"
            aria-hidden="true"
          >
            <path d="M.293 0l22 22-22 22h1.414l22-22-22-22H.293z" />
          </svg>
        <% end %>
      </div>
    </li>
    """
  end

  def home_icon(assigns) do
    ~H"""
    <svg
      class="h-5 w-5 flex-shrink-0"
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="true"
      data-slot="icon"
    >
      <path
        fill-rule="evenodd"
        d="M9.293 2.293a1 1 0 0 1 1.414 0l7 7A1 1 0 0 1 17 11h-1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6H3a1 1 0 0 1-.707-1.707l7-7Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def side_and_topbar(assigns) do
    ~H"""
    <div>
      <.topbar
        current_organisation={@current_organisation}
        current_user={@current_user}
        language={@language}
      />

      <.desktop_sidebar
        current_organisation={@current_organisation}
        current_user={@current_user}
        language={@language}
      />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def mobile_sidebar(assigns) do
    ~H"""
    <div class="grow h-[100vh] flex flex-col gap-4">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 pb-4 ring-1 ring-white/10">
        <.link navigate="/" class="flex h-16 shrink-0 items-center">
          <img
            class="h-8 w-auto"
            src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500"
            alt={dgettext("aria", "Company logo")}
          />
        </.link>

        <nav class="flex flex-1 flex-col" aria-label={dgettext("aria", "Main navigation")}>
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" class="-mx-2 space-y-1">
                <.organisation_link
                  current_organisation={@current_organisation}
                  current_user={@current_user}
                />

                <li>
                  <.link
                    :if={@current_organisation}
                    navigate={~p"/organisations/#{@current_organisation}/today"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Today's Time Tracker") %>
                  </.link>
                </li>

                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Team") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Projects") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                      />
                    </svg>
                    <%= dgettext("navigation", "Calendar") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75"
                      />
                    </svg>
                    <%= dgettext("navigation", "Documents") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M10.5 6a7.5 7.5 0 107.5 7.5h-7.5V6z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M13.5 10.5H21A7.5 7.5 0 0013.5 3v7.5z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Reports") %>
                  </a>
                </li>
              </ul>
            </li>
            <li :if={@current_organisation}>
              <div class="text-xs font-semibold leading-6 text-gray-400">
                <%= @current_organisation.name %>
              </div>
              <ul role="list" class="-mx-2 mt-2 space-y-1">
                <li>
                  <.link
                    navigate={~p"/organisations/#{@current_organisation}/groups"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                      G
                    </span>
                    <span class="truncate">
                      <%= dgettext("navigation", "Groups") %>
                    </span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/organisations/#{@current_organisation}/projects"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                      P
                    </span>
                    <span class="truncate">
                      <%= dgettext("navigation", "Projects") %>
                    </span>
                  </.link>
                </li>
              </ul>
            </li>
            <li class="mt-auto">
              <a
                href="#"
                class="group -mx-2 flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
              >
                <svg
                  class="h-6 w-6 shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <%= dgettext("navigation", "Your Profile") %>
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </div>
    """
  end

  defp topbar(assigns) do
    ~H"""
    <div class="lg:pl-72">
      <div class="sticky top-0 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
        <div class="lg:hidden">
          <button
            type="button"
            class="-m-2.5 p-2.5 text-gray-700"
            phx-click={
              JS.show(to: "#mobile-sidebar", transition: "fade-in-scale")
              |> JS.add_class("z-[1000]", to: "#mobile-sidebar")
            }
          >
            <span class="sr-only">Open sidebar</span>
            <svg
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>

          <div
            id="mobile-sidebar"
            class="hidden absolute top-0 w-[100%] h-[100vh] border-none bg-white left-0"
          >
            <div class="flex gap-4">
              <.mobile_sidebar
                current_organisation={@current_organisation}
                current_user={@current_user}
                language={@language}
              />
              <button
                type="button"
                class="p-4 text-black self-start"
                phx-click={
                  JS.hide(to: "#mobile-sidebar", transition: "slide-right")
                  |> JS.remove_class("z-[1000]", to: "#mobile-sidebar")
                }
              >
                <.close_icon />
              </button>
            </div>
          </div>
        </div>

        <div class="h-6 w-px bg-gray-900/10 lg:hidden"></div>
        <div class="flex justify-between flex-1">
          <div class="w-[50%] md:w-[70%] lg:w-[50%] 2xl:w-[70%]">
            <input
              id="search-field"
              class="block h-full w-[100%] border-0  text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm"
              placeholder={dgettext("navigation", "Search...")}
              type="search"
              name="search"
            />
          </div>
          <div>
            <div class="flex items-center gap-x-4 lg:gap-x-6">
              <button type="button" class="-m-2.5 p-2.5 text-gray-400 hover:text-gray-500">
                <span class="sr-only">View notifications</span>
                <svg
                  class="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"
                  />
                </svg>
              </button>

              <div class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-900/10" aria-hidden="true"></div>

              <div class="relative">
                <button
                  type="button"
                  class="-m-1.5 flex items-center p-1.5"
                  id="user-menu-button"
                  aria-expanded="false"
                  aria-haspopup="true"
                  phx-click={JS.toggle(to: "#user-menu", in: "fade-in-scale", out: "fade-out-scale")}
                >
                  <span class="hidden lg:flex lg:items-center">
                    <span class="ml-4 text-sm font-medium leading-6 text-gray-900" aria-hidden="true">
                      <%= if @current_user do %>
                        <%= @current_user.as_string %>
                      <% else %>
                        <.link navigate="/login" class="text-blue-500">
                          <%= dgettext("navigation", "Login") %>
                        </.link>
                        <span>
                          |
                        </span>
                        <.link navigate="/register" class="text-blue-500">
                          <%= dgettext("navigation", "Register") %>
                        </.link>
                      <% end %>
                    </span>
                    <svg
                      class="ml-2 h-5 w-5 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                </button>

                <.dropdown_items current_user={@current_user} language={@language} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def desktop_sidebar(assigns) do
    ~H"""
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center">
          <img
            class="h-8 w-auto"
            src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500"
            alt={dgettext("aria", "Company logo")}
          />
        </div>
        <nav class="flex flex-1 flex-col" aria-label={dgettext("aria", "Main navigation")}>
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" class="-mx-2 space-y-1">
                <.organisation_link
                  current_organisation={@current_organisation}
                  current_user={@current_user}
                />
                <li>
                  <.link
                    :if={@current_organisation}
                    navigate={~p"/organisations/#{@current_organisation}/today"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Today's Time Tracker") %>
                  </.link>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Team") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Projects") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                      />
                    </svg>
                    <%= dgettext("navigation", "Calendar") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75"
                      />
                    </svg>
                    <%= dgettext("navigation", "Documents") %>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M10.5 6a7.5 7.5 0 107.5 7.5h-7.5V6z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M13.5 10.5H21A7.5 7.5 0 0013.5 3v7.5z"
                      />
                    </svg>
                    <%= dgettext("navigation", "Reports") %>
                  </a>
                </li>
              </ul>
            </li>
            <li :if={@current_organisation}>
              <div class="text-xs font-semibold leading-6 text-gray-400">
                <%= @current_organisation.name %>
              </div>
              <ul role="list" class="-mx-2 mt-2 space-y-1">
                <li>
                  <.link
                    navigate={~p"/organisations/#{@current_organisation}/groups"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                      G
                    </span>
                    <span class="truncate">
                      <%= dgettext("navigation", "Groups") %>
                    </span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/organisations/#{@current_organisation}/projects"}
                    class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                  >
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                      P
                    </span>
                    <span class="truncate">
                      <%= dgettext("navigation", "Projects") %>
                    </span>
                  </.link>
                </li>
              </ul>
            </li>
            <li class="mt-auto">
              <a
                href="#"
                class="group -mx-2 flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
              >
                <svg
                  class="h-6 w-6 shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <%= dgettext("navigation", "Your Profile") %>
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </div>
    """
  end

  defp dropdown_items(assigns) do
    ~H"""
    <div
      class="absolute right-0 z-10 mt-2.5  origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none hidden"
      role="menu"
      aria-orientation="vertical"
      aria-labelledby="user-menu-button"
      tabindex="-1"
      id="user-menu"
      phx-click-away={JS.hide(to: "#user-menu", transition: "fade-out-scale")}
    >
      <div :if={@current_user} class="flex  p-2 flex-col gap-2">
        <.link navigate="/edit_profile">
          <%= dgettext("navigation", "Edit Profile") %>
        </.link>
        <.link navigate="/auth/user/sign-out">
          <%= dgettext("navigation", "Sign out") %>
        </.link>
      </div>

      <div :if={@current_user == nil} class="flex p-2 flex-col gap-2">
        <.link navigate="/login">
          <%= dgettext("navigation", "Login") %>
        </.link>
        <.link navigate="/register">
          <%= dgettext("navigation", "Register") %>
        </.link>
      </div>
    </div>
    """
  end

  defp close_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="size-6"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
    </svg>
    """
  end

  defp organisation_link(%{current_organisation: nil} = assigns) do
    ~H"""
    <li :if={Ash.can?({Omedis.Accounts.Organisation, :create}, @current_user)}>
      <.link
        navigate={~p"/organisations/new"}
        class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
      >
        <svg
          class="h-6 w-6 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
          />
        </svg>
        <%= dgettext("navigation", "Create new organisation") %>
      </.link>
    </li>
    """
  end

  defp organisation_link(assigns) do
    ~H"""
    <li>
      <.link
        navigate={~p"/organisations/#{@current_organisation}"}
        class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
      >
        <svg
          class="h-6 w-6 shrink-0"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
          />
        </svg>
        <%= @current_organisation.name %>
      </.link>
    </li>
    """
  end

  attr :class, :string, default: nil
  attr :color, :string, required: true
  attr :rest, :global, include: ~w(disabled form name value)
  attr :type, :string, default: nil

  slot :inner_block, required: true

  def custom_color_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg py-2 px-3",
        "text-sm font-semibold leading-6",
        @class
      ]}
      style={[
        "background: #{@color}; color: #{text_color_for_background(@color)};"
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp text_color_for_background(color_code) do
    if contrasting_color(color_code) == "#ffffff", do: "#ffffff", else: "#000000"
  end

  defp contrasting_color(hex_color) do
    {r, g, b} = hex_to_rgb(hex_color)
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    if luminance > 0.5, do: "#000000", else: "#ffffff"
  end

  defp hex_to_rgb(hex) do
    hex = String.replace(hex, "#", "")

    {r, g, b} =
      hex
      |> String.to_charlist()
      |> Enum.chunk_every(2)
      |> Enum.map(&List.to_integer(&1, 16))
      |> List.to_tuple()

    {r, g, b}
  end
end
