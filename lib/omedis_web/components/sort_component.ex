defmodule OmedisWeb.Components.SortComponent do
  @moduledoc false

  use Phoenix.Component

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    current_sort_by = assigns.options[:sort_by]
    current_sort_order = assigns.options[:sort_order]

    next_sort_order =
      case {assigns.sort_by == current_sort_by, current_sort_order} do
        {true, :asc} -> :desc
        {true, :desc} -> :asc
        {false, _} -> :asc
      end

    assigns =
      assign(assigns,
        next_sort_order: next_sort_order,
        current_sort_by: current_sort_by,
        current_sort_order: current_sort_order
      )

    ~H"""
    <.link patch={build_sort_params(@sort_by, @next_sort_order)} class="group inline-flex">
      <%= render_slot(@inner_block) %>
      <span class="ml-2 flex-none rounded">
        <%= if @sort_by == @current_sort_by do %>
          <%= if @current_sort_order == :asc do %>
            ↑
          <% else %>
            ↓
          <% end %>
        <% end %>
      </span>
    </.link>
    """
  end

  defp build_sort_params(sort_by, sort_order) do
    [sort_by: sort_by, sort_order: sort_order]
  end

  # def sort_by_inserted_at(socket) do

  # end
end
