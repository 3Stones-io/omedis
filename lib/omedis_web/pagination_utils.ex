defmodule OmedisWeb.PaginationUtils do
  @moduledoc """
  Utility functions.
  """
  def maybe_convert_page_to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> int_value
      _ -> 1
    end
  end

  def maybe_convert_page_to_integer(value) when is_integer(value), do: value
  def maybe_convert_page_to_integer(_value), do: 1

  def list_paginated(socket, params, stream_name, paginate_fn) do
    records_per_page = socket.assigns.number_of_records_per_page
    page = maybe_convert_page_to_integer(params["page"])
    offset = calculate_offset(params, records_per_page)

    case paginate_fn.(offset) do
      {:ok, %{count: total_count, results: items}} ->
        total_pages = max(1, ceil(total_count / records_per_page))
        current_page = min(page, total_pages)

        socket
        |> Phoenix.Component.assign(:current_page, current_page)
        |> Phoenix.Component.assign(:total_pages, total_pages)
        |> Phoenix.LiveView.stream(stream_name, items, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp calculate_offset(params, records_per_page) do
    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, maybe_convert_page_to_integer(page))
        (page_value - 1) * records_per_page

      _ ->
        0
    end
  end
end
