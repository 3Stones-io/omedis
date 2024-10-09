defmodule OmedisWeb.PaginationComponent do
  @moduledoc false

  use OmedisWeb, :html

  def pagination(assigns) do
    show_full_pagination = assigns.total_pages <= 6

    assigns = assign(assigns, :show_full_pagination, show_full_pagination)

    ~H"""
    <div class="flex items-center justify-between border-t border-gray-200 bg-white py-5">
      <div class="flex flex-1 justify-between sm:hidden">
        <%= if @current_page > 1 do %>
          <button
            phx-click={JS.push("change_page", value: %{page: @current_page - 1, limit: @limit})}
            class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <%= with_locale(@language, fn -> %>
              <%= gettext("Previous") %>
            <% end) %>
          </button>
        <% else %>
          <button
            class="relative inline-flex items-center rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-50"
            disabled
          >
            <%= with_locale(@language, fn -> %>
              <%= gettext("Previous") %>
            <% end) %>
          </button>
        <% end %>
        <%= if @current_page == @total_pages do %>
          <button
            class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-50"
            disabled
          >
            <%= with_locale(@language, fn -> %>
              <%= gettext("Next") %>
            <% end) %>
          </button>
        <% else %>
          <button
            phx-click={JS.push("change_page", value: %{page: @current_page + 1, limit: @limit})}
            class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <%= with_locale(@language, fn -> %>
              <%= gettext("Next") %>
            <% end) %>
          </button>
        <% end %>
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
            <%= if @current_page > 1 do %>
              <button
                phx-click={JS.push("change_page", value: %{page: @current_page - 1, limit: @limit})}
                class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
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
              </button>
            <% else %>
              <button
                disabled
                class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 focus:z-20 focus:outline-offset-0"
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
              </button>
            <% end %>
            <%= if @show_full_pagination do %>
              <%= for page <- 1..@total_pages do %>
                <button
                  phx-click={JS.push("change_page", value: %{page: page, limit: @limit})}
                  aria-current="page"
                  disabled={page == @current_page}
                  class={[
                    "relative z-10 inline-flex items-center px-4 py-2 text-sm font-semibold focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                    if(page == @current_page,
                      do: "bg-zinc-900 hover:bg-zinc-700 text-white",
                      else: "hover:bg-gray-50 ring-1 ring-inset ring-gray-300 text-gray-900"
                    )
                  ]}
                >
                  <%= page %>
                </button>
              <% end %>
            <% else %>
              <%= for page <- Enum.take(1..@total_pages, 3) do %>
                <button
                  phx-click={JS.push("change_page", value: %{page: page, limit: @limit})}
                  aria-current="page"
                  class={[
                    "relative z-10 inline-flex items-center px-4 py-2 text-sm font-semibold focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                    if(page == @current_page,
                      do: "bg-zinc-900 hover:bg-zinc-700 text-white",
                      else: "hover:bg-gray-50 ring-1 ring-inset ring-gray-300 text-gray-900"
                    )
                  ]}
                >
                  <%= page %>
                </button>
              <% end %>
              <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">
                ...
              </span>
              <%= for page <- Enum.take(1..@total_pages, -3) do %>
                <button
                  phx-click={JS.push("change_page", value: %{page: page, limit: @limit})}
                  aria-current="page"
                  class={[
                    "relative z-10 inline-flex items-center px-4 py-2 text-sm font-semibold focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                    if(page == @current_page,
                      do: "bg-zinc-900 hover:bg-zinc-700 text-white",
                      else: "hover:bg-gray-50 ring-1 ring-inset ring-gray-300 text-gray-900"
                    )
                  ]}
                >
                  <%= page %>
                </button>
              <% end %>
            <% end %>
            <%= if @current_page < @total_pages do %>
              <button
                phx-click={JS.push("change_page", value: %{page: @current_page + 1, limit: @limit})}
                class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
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
              </button>
            <% else %>
              <button
                disabled
                class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 focus:z-20 focus:outline-offset-0"
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
              </button>
            <% end %>
          </nav>
        </div>
      </div>
    </div>
    """
  end
end
