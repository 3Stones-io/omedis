defmodule OmedisWeb.TimeTracking do
  @moduledoc """
  Provides components for time tracking and visualization.

  This module includes functions for rendering a time tracking dashboard,
  individual time entries, and utility functions for time calculations.
  """
  use Phoenix.Component
  alias Omedis.Accounts.LogEntry

  attr :categories, :list, required: true
  attr :start_at, :any, required: true
  attr :end_at, :any, required: true
  attr :current_time, :any, required: true

  @doc """
  Renders the main dashboard component.

  ## Example

      <.dashboard_component
        categories={[%{name: "Work", color_code: "#FF0000", log_entries: [...]}, ...]}
        starts_a={~T[08:00:00]}
        ends_a={~T[18:00:00]}
        current_time={~T[13:30:00]}
      />
  """
  def dashboard_component(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.dashboard_card
        categories={@categories}
        start_at={@start_at}
        end_at={@end_at}
        current_time={@current_time}
      />
    </div>
    """
  end

  @doc """
  Dashboard card component. This holds the whole dashboard.
  """

  attr :categories, :list, required: true
  attr :start_at, :any, required: true
  attr :end_at, :any, required: true
  attr :current_time, :any, required: true

  def dashboard_card(assigns) do
    ~H"""
    <div class="md:w-[50%] w-[90%] h-[70vh]  m-auto flex justify-start gap-1 items-end">
      <div class="md:w-[40%]  flex justify-start flex-col gap-5 h-[100%]">
        <%= for category <- @categories do %>
          <.category_button category={category} />
        <% end %>
      </div>

      <div class="w-[30%] flex items-end justify-end gap-4 h-[100%] ">
        <div class="w-[40%] relative h-[100%]">
          <%= for entry <- format_entries(@categories) do %>
            <div
              class="absolute w-[100%]"
              style={
                "top: #{get_top_to_use_for_entry(entry, @start_at, @end_at)}%;
                background-color: #{entry.color_code};
                height: #{get_height_to_use_for_entry(entry, @start_at, @end_at)}%;
                "
              }
            />
          <% end %>
        </div>
      </div>

      <div class="relative h-[100%]">
        <div class="w-[100%] h-[100%]  flex flex-row gap-1">
          <div class=" h-[100%] ">
            <p class="w-[5px] bg-black h-[100%]"></p>
          </div>

          <div class="w-[100%] h-[100%] flex flex-row gap-1">
            <.time_intervals start_at={@start_at} end_at={@end_at} />
          </div>
        </div>

        <div
          class="md:w-[50px] w-[40px] h-[3px] bg-red-500 absolute "
          style={"top: #{get_top_to_use_for_current_time(@start_at, @end_at, @current_time)}%; position: absolute "}
        />
      </div>
    </div>
    """
  end

  @doc """
  Time intervals component. This holds the time intervals from the minimum time to the maximum time , in intervals of hours , the interval
  is calculated based on the total hours between the minimum and maximum time.
  We have a total of maximum 12 intervals.
  """

  attr :start_at, :any, required: true
  attr :end_at, :any, required: true

  def time_intervals(assigns) do
    ~H"""
    <div class="w-[100%] h-[100%] flex flex-col justify-between  gap-1">
      <%= for time_interval <- get_time_intervals_array(@start_at, @end_at) do %>
        <p>
          <%= format_time(time_interval) %>
        </p>
      <% end %>
    </div>
    """
  end

  @doc """
  Get the time intervals array based on the start and end time.

  ## Example

      iex> get_time_intervals_array(~T[08:00:00], ~T[18:00:00])
      [~T[08:00:00], ~T[09:00:00], ~T[10:00:00], ~T[11:00:00], ~T[12:00:00],
       ~T[13:00:00], ~T[14:00:00], ~T[15:00:00], ~T[16:00:00], ~T[17:00:00],
       ~T[18:00:00]]
  """
  def get_time_intervals_array(start_at, end_at) do
    total_hours = Time.diff(end_at, start_at, :hour)
    max_intervals = 12

    interval_step =
      if total_hours + 1 > max_intervals do
        div(total_hours + 1, max_intervals)
      else
        1
      end

    Enum.to_list(0..total_hours)
    |> Enum.filter(fn hour -> rem(hour, interval_step) == 0 end)
    |> Enum.map(fn hour -> Time.add(start_at, hour * 3600, :second) end)
  end

  @doc """
  Get the height to use for the entry based on the total time spent on the entry and the maximum time in minutes.

  ## Example

      iex> entry = %{start_at: ~T[09:00:00], end_at: ~T[11:00:00]}
      iex> get_height_to_use_for_entry(entry, ~T[08:00:00], ~T[18:00:00])
      16.666666666666668 # Represents 16.67% of the total height
  """

  def get_height_to_use_for_entry(entry, start_at, end_at) do
    time_spent =
      if entry.end_at == nil do
        Time.diff(Time.utc_now(), entry.start_at, :minute)
      else
        Time.diff(entry.end_at, entry.start_at, :minute)
      end

    maximum_time_in_minutes = Time.diff(end_at, start_at, :minute)
    time_spent / maximum_time_in_minutes * 100
  end

  @doc """
  Get the absolute top % to use for the entry based on the total time spent on the entry and the maximum time in minutes.

  ## Example

      iex> entry = %{start_at: ~T[10:00:00], end_at: ~T[12:00:00]}
      iex> get_top_to_use_for_entry(entry, ~T[08:00:00], ~T[18:00:00])
      20.0 # Represents 20% from the top
  """
  def get_top_to_use_for_entry(entry, start_at, end_at) do
    time_difference_between_start_at_and_entry = Time.diff(entry.start_at, start_at, :minute)

    time_difference_between_start_at_and_entry / Time.diff(end_at, start_at, :minute) * 100
  end

  @doc """
  Get the absolute top % to use for the current time based on the total time spent on the entry and the maximum time in minutes.

  ## Example

      iex> get_top_to_use_for_current_time(~T[08:00:00], ~T[18:00:00], ~T[13:00:00])
      50.0 # Represents 50% from the top
  """
  def get_top_to_use_for_current_time(start_at, end_at, current_time) do
    time_spent = Time.diff(current_time, start_at, :minute)
    maximum_time_in_minutes = Time.diff(end_at, start_at, :minute)
    time_spent / maximum_time_in_minutes * 100
  end

  @doc """
  The category button component. This holds the category button.
  """

  attr :category, :any, required: true

  def category_button(assigns) do
    ~H"""
    <div class="flex flex-row gap-2 items-center">
      <p :if={active_log_category?(@category.id)} class="h-[10px] w-[10px] bg-green-500 rounded-full" />

      <button
        class="w-[100%] h-[100%] h-[40px] rounded-md"
        phx-click="select_log_category"
        phx-value-log_category_id={@category.id}
        style={"background-color: #{@category.color_code};"}
      >
        <span class="text-white text-sm p-2  md:text-base">
          <%= @category.name %>
        </span>
      </button>
    </div>
    """
  end

  @doc """
  This formats the time into 24-hour format for user readability.

  ## Example

      iex> format_time(~T[14:30:00])
      "14:30"
  """
  def format_time(%Time{hour: hour, minute: minute}) do
    "#{String.pad_leading(Integer.to_string(hour), 2, "0")}:#{String.pad_leading(Integer.to_string(minute), 2, "0")}"
  end

  @doc """
  This formats the entries to be used in the dashboard card.
  The entries are listed in order of their start time.
  They are also assigned a color code based on their category.

  ## Example

      iex> categories = [
      ...>   %{name: "Work", color_code: "#FF0000", log_entries: [%{start_at: ~T[09:00:00], end_at: ~T[12:00:00]}]},
      ...>   %{name: "Break", color_code: "#00FF00", log_entries: [%{start_at: ~T[12:00:00], end_at: ~T[13:00:00]}]}
      ...> ]
      iex> format_entries(categories)
      [
        %{start_at: ~T[09:00:00], end_at: ~T[12:00:00], color_code: "#FF0000"},
        %{start_at: ~T[12:00:00], end_at: ~T[13:00:00], color_code: "#00FF00"}
      ]
  """
  def format_entries(categories) do
    categories
    |> Enum.map(fn category ->
      category.log_entries
    end)
    |> List.flatten()
    |> Enum.filter(fn entry ->
      entry.created_at |> DateTime.to_date() == Date.utc_today()
    end)
    |> Enum.sort_by(fn %{start_at: start_at, end_at: end_at} -> {start_at, end_at} end)
    |> Enum.map(fn x ->
      %{
        start_at: x.start_at,
        end_at: x.end_at,
        color_code:
          Enum.find(categories, fn category ->
            category.log_entries |> Enum.find(fn entry -> entry.start_at == x.start_at end)
          end).color_code
      }
    end)
  end

  attr :start_at, :any, required: true
  attr :end_at, :any, required: true
  attr :events, :list, required: true

  def time_tracking(assigns) do
    ~H"""
    <div class="w-[100%] h-[100%] flex flex-row">
      <div class="w-[10%] h-[100%]">
        <.time_intervals start_at={@start_at} end_at={@end_at} />
      </div>
      <div class="w-[90%] h-[100%] relative">
        <%= for event <- @events do %>
          <div
            class="absolute w-[100%] bg-gray-200 rounded-md p-2"
            style={"top: #{calculate_top_position(event.start_at, @start_at, @end_at)}%; height: #{calculate_height(event.start_at, event.end_at, @start_at, @end_at)}%;"}
          >
            <%= event.title %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Calculates the top position for an event as a percentage of the timeline.

  ## Example

      iex> calculate_top_position(~T[10:00:00], ~T[08:00:00], ~T[18:00:00])
      20.0 # Represents 20% from the top
  """
  def calculate_top_position(event_start, timeline_start, timeline_end) do
    total_minutes = Time.diff(timeline_end, timeline_start, :minute)
    event_minutes = Time.diff(event_start, timeline_start, :minute)
    event_minutes / total_minutes * 100
  end

  @doc """
  Calculates the height of an event as a percentage of the timeline.

  ## Example

      iex> calculate_height(~T[10:00:00], ~T[12:00:00], ~T[08:00:00], ~T[18:00:00])
      20.0 # Represents 20% of the total height
  """
  def calculate_height(event_start, event_end, timeline_start, timeline_end) do
    total_minutes = Time.diff(timeline_end, timeline_start, :minute)
    event_duration = Time.diff(event_end, event_start, :minute)
    event_duration / total_minutes * 100
  end

  defp active_log_category?(log_category_id) do
    {:ok, log_entries} = LogEntry.by_log_category_today(%{log_category_id: log_category_id})

    case Enum.find(log_entries, fn log_entry -> log_entry.end_at == nil end) do
      nil ->
        false

      _log_entry ->
        true
    end
  end
end
