defmodule OmedisWeb.PaginationComponent do
  @moduledoc false

  use OmedisWeb, :html

  def pagination(assigns) do
    assigns =
      assign(assigns, :visible_pages, visible_pages(assigns.current_page, assigns.total_pages))

    ~H"""
    <div
      :if={@total_pages > 1}
      class="flex items-center justify-between border-t border-gray-200 bg-white py-5"
    >
      <div class="flex flex-1 justify-between sm:hidden">
        <.page_link
          patch={@current_page > 1 && @resource_path <> "?page=#{@current_page - 1}"}
          class={[
            "border rounded-md border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50",
            @current_page <= 1 && "cursor-not-allowed opacity-50"
          ]}
        >
          <%= with_locale(@language, fn -> %>
            <%= gettext("Previous") %>
          <% end) %>
        </.page_link>
        <.page_link
          patch={@current_page != @total_pages && @resource_path <> "?page=#{@current_page + 1}"}
          class={[
            "ml-3 border rounded-md border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50",
            @current_page == @total_pages && "cursor-not-allowed opacity-50"
          ]}
        >
          <%= with_locale(@language, fn -> %>
            <%= gettext("Next") %>
          <% end) %>
        </.page_link>
      </div>
      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            <%= with_locale(@language, fn -> %>
              <%= gettext("Showing page") %>
            <% end) %>
            <span class="font-medium text-gray-900"><%= @current_page %></span>
            <%= with_locale(@language, fn -> %>
              <%= gettext("of") %>
            <% end) %>
            <span class="font-medium text-gray-900"><%= @total_pages %></span>
          </p>
        </div>
        <div>
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.page_link
              patch={@current_page > 1 && @resource_path <> "?page=#{@current_page - 1}"}
              class={[
                "rounded-l-md p-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
                @current_page <= 1 && "cursor-not-allowed opacity-50"
              ]}
            >
              <span class="sr-only">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Previous") %>
                <% end) %>
              </span>

              <svg
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  fill-rule="evenodd"
                  d="M11.78 5.22a.75.75 0 0 1 0 1.06L8.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06l4.25-4.25a.75.75 0 0 1 1.06 0Z"
                  clip-rule="evenodd"
                />
              </svg>
            </.page_link>
            <%= for page <- @visible_pages do %>
              <%= if page == :ellipsis do %>
                <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">
                  ...
                </span>
              <% else %>
                <.page_link
                  patch={@resource_path <> "?page=#{page}"}
                  aria-current={page == @current_page && "page"}
                  class={[
                    "px-4 py-2",
                    page == @current_page && "bg-zinc-900 hover:bg-zinc-700 text-white",
                    page != @current_page &&
                      "hover:bg-gray-50 ring-1 ring-inset ring-gray-300 text-gray-900"
                  ]}
                >
                  <%= page %>
                </.page_link>
              <% end %>
            <% end %>
            <.page_link
              patch={@current_page < @total_pages && @resource_path <> "?page=#{@current_page + 1}"}
              class={[
                "p-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
                @current_page == @total_pages && "cursor-not-allowed opacity-50"
              ]}
            >
              <span class="sr-only">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Next") %>
                <% end) %>
              </span>
              <svg
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  fill-rule="evenodd"
                  d="M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </.page_link>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  defp visible_pages(current_page, total_pages) do
    cond do
      total_pages <= 7 ->
        Enum.to_list(1..total_pages)

      current_page <= 4 ->
        [1, 2, 3, 4, 5, :ellipsis, total_pages]

      current_page >= total_pages - 3 ->
        [
          1,
          :ellipsis,
          total_pages - 4,
          total_pages - 3,
          total_pages - 2,
          total_pages - 1,
          total_pages
        ]

      true ->
        [1, :ellipsis, current_page - 1, current_page, current_page + 1, :ellipsis, total_pages]
    end
  end

  attr :class, :list, default: []
  attr :patch, :string, required: true
  attr :rest, :global, doc: "arbitrary HTML attributes to add to the component."

  slot :inner_block, required: true

  def page_link(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={[
        "relative z-10 inline-flex items-center text-sm focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
