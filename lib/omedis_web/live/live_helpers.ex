defmodule OmedisWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.Component

  def on_mount(:assign_default_pagination_assigns, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:current_page, 1)
     |> assign(:total_pages, 1)}
  end
end
