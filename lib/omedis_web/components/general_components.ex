defmodule OmedisWeb.GeneralComponents do
  @moduledoc """
  Provides general components for the application.
  """
  use Phoenix.Component

  use Gettext, backend: OmedisWeb.Gettext

  def top_navigation(assigns) do
    ~H"""
    <div class="w-[100%]   text-base    gap-5  z-20  fixed top-0">
      <div class="w-[20%]  h-[100%] bg-gray-900" />
      <div class="w-[100%] ml-[0%] md:ml-[20%] md:w-[80%] p-4 bg-white border-[1px] border-b border-gray-200">
        <div class="justify-end items-center w-[95%] mx-auto flex">
          <div class="flex items-center gap-5">
            <div class="block md:hidden" x-data="{ open: false }" @click="open = !open">
              <p class="text-black ">
                <.menu_bar />
              </p>

              <div
                x-show="open"
                class=" absolute top-0 w-[100vw] h-[100vh] flex gap-4 items-start border-none  bg-white left-0 "
              >
                <div
                  @click.outside="open = false"
                  @keydown.escape.window="open = false"
                  x-show="open"
                  x-transition
                  x-cloak
                  class="w-[75%]  h-[100%]  bg-white "
                >
                  <.mobile_navigation />
                </div>

                <div class="p-4 text-black" @click="open = false" x-show="open" x-transition x-cloak>
                  <.close_icon />
                </div>
              </div>
            </div>
            <div class="flex items-center gap-3 md:gap-5">
              <div>
                <.top_notification_bell />
              </div>

              <div
                x-data="{ open: false }"
                @click="open = !open"
                class="flex items-center gap-2 cursor-pointer "
              >
                <div>
                  Img
                </div>
                <p class="hidden md:block">
                  Name Here
                </p>

                <button class="hidden  md:block" type="button">
                  <.arrow_down />
                </button>
                <div
                  @click.outside="open = false"
                  @keydown.escape.window="open = false"
                  x-show="open"
                  x-transition
                  x-cloak
                  class="absolute py-3 top-8 right-2"
                >
                  <.dropdown_items />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp arrow_down(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="size-6"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
    </svg>
    """
  end

  def top_notification_bell(assigns) do
    ~H"""
    <div class="flex gap-1 text-gray-500">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="size-6"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0"
        />
      </svg>
    </div>
    """
  end

  def mobile_navigation(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 p-4">
      <div class="flex flex-col gap-2">
        <%= for item <- nav_items() do %>
          <.nav_item item={item} />
        <% end %>
      </div>
    </div>
    """
  end

  defp menu_bar(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="size-6"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
      />
    </svg>
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

  defp dropdown_items(assigns) do
    ~H"""
    <div class="    text-gray-700 p-2 block w-[80%] ml-[20%]  py-2 text-sm bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none flex flex-col rounded-md gap-2  ">
      Dropdowm Items Here
    </div>
    """
  end

  def desktop_sidebar_navigation(assigns) do
    ~H"""
    <div class="w-[20%] md:block hidden z-90 h-[100vh] flex justify-between fixed top-0 pt-[50px] bg-gray-900  pb-4 ring-1 ring-white/10">
      <div class="h-[100%] flex flex-col w-[100%] justify-between ">
        <div class="flex flex-col gap-2 p-4">
          <%= for item <- nav_items() do %>
            <.nav_item item={item} />
          <% end %>
        </div>

        <div class="flex flex-col gap-2 p-4">
          <p class="text-white">
            Your Teams
          </p>
          <%= for item <- nav_items() do %>
            <.nav_item item={item} />
          <% end %>
        </div>

        <div class="flex flex-col gap-2 p-4">
          <.nav_item item={settings_item()} />
        </div>
      </div>
    </div>
    """
  end

  def nav_item(assigns) do
    ~H"""
    <.top_navigation_entry phx-no-format>

    <div class="flex flex-row items-center gap-2" >
      <i class={"#{@item.icon}  text-gray-400 text-base"}></i>
      <span><%= @item.name %></span>
      </div>


    </.top_navigation_entry>
    """
  end

  def top_navigation_entry(assigns) do
    ~H"""
    <button
      type="button"
      class="relative cursor-pointer transition-all  text-gray-400 hover:text-white hover:bg-gray-800 transition-all ease-in-out duration-500 w-[100%]   flex flex-row items-center justify-start  rounded-md group  gap-1.5 py-3 px-3   shadow-none drop-shadow-none"
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp nav_items do
    [
      %{name: gettext("Home"), icon: "fa fa-home"},
      %{name: gettext("Bookmarks"), icon: "fa fa-bookmark"}
    ]
  end

  defp settings_item do
    %{name: gettext("Settings"), icon: "fa fa-cog"}
  end
end
