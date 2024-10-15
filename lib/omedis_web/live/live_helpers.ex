defmodule OmedisWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.Component

  def on_mount(:assign_default_pagination_assigns, _params, _session, socket) do
    number_of_records_per_page = Application.get_env(:omedis, :pagination_default_limit)

    {:cont,
     socket
     |> assign(:current_page, 1)
     |> assign(:number_of_records_per_page, number_of_records_per_page)
     |> assign(:total_pages, 1)}
  end
end
