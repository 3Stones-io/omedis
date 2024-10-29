defmodule OmedisWeb.TimeTracking do
  @moduledoc """
  Provides components for time tracking and visualization.

  This module includes functions for rendering a time tracking dashboard,
  individual time entries, and utility functions for time calculations.
  """
  use Phoenix.Component
  use Gettext, backend: OmedisWeb.Gettext

  import Gettext, only: [with_locale: 2]

  attr :categories, :list, required: true
  attr :start_at, :any, required: true
  attr :end_at, :any, required: true
  attr :current_time, :any, required: true
  attr :log_entries, :list, required: true
  attr :language, :any, required: true
  attr :active_log_category_id, :string, required: true

  @doc """
  Renders the main dashboard component.

  ## Example

      <.dashboard_component
        categories={[%{name: "Work", color_code: "#FF0000", log_entries: [...]}, ...]}
        starts_a={~T[08:00:00]}
        ends_a={~T[18:00:00]}
        current_time={~T[13:30:00]}
        language="en"
        log_entries={[%{start_at: ~T[09:00:00], end_at: ~T[12:00:00], color_code: "#FF0000"}, ...]}
      />
  """
  def dashboard_component(assigns) do
    ~H"""
    <div class="w-[100%] flex flex-col gap-1 ">
      <%= if Enum.empty?(@categories) do %>
        <.no_log_categories language={@language} />
      <% else %>
        <.dashboard_card
          active_log_category_id={@active_log_category_id}
          categories={@categories}
          start_at={@start_at}
          end_at={@end_at}
          log_entries={@log_entries}
          language={@language}
          current_time={@current_time}
        />
      <% end %>
    </div>
    """
  end

  def no_log_categories(assigns) do
    ~H"""
    <div class="w-[100%] h-[30vh] flex justify-center items-center">
      <%= with_locale(@language, fn -> %>
        <p>
          <%= gettext("No log categories are defined yet.") %>
        </p>
      <% end) %>
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
  attr :log_entries, :list, required: true
  attr :language, :any, required: true
  attr :active_log_category_id, :string, required: true

  def dashboard_card(assigns) do
    ~H"""
    <div class="md:w-[50%] w-[90%] h-[70vh]  m-auto flex justify-start gap-1 items-end">
      <div class="md:w-[40%]  flex justify-start flex-col gap-5 h-[100%]">
        <%= for category <- @categories do %>
          <.category_button
            active_log_category_id={@active_log_category_id}
            category={category}
            language={@language}
            current_time={@current_time}
          />
        <% end %>
      </div>

      <div class="w-[30%] flex items-end justify-end gap-4 h-[100%] ">
        <div class="w-[40%] relative h-[100%]">
          <%= for entry <- @log_entries do %>
            <div
              class="absolute w-[100%]"
              style={
                "top: #{get_top_to_use_for_entry(entry, @start_at, @end_at)}%;
                background-color: #{entry.color_code};
                height: #{get_height_to_use_for_entry(entry, @current_time , @start_at, @end_at)}%;
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
      iex> get_height_to_use_for_entry(entry, ~T[10:00:00],  ~T[08:00:00], ~T[18:00:00])
      16.666666666666668 # Represents 16.67% of the total height
  """

  def get_height_to_use_for_entry(entry, current_time, start_at, end_at) do
    time_spent =
      if entry.end_at == nil do
        Time.diff(current_time, entry.start_at, :minute)
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
  attr :current_time, :any, required: true
  attr :language, :any, required: true
  attr :active_log_category_id, :string, required: true

  def category_button(assigns) do
    ~H"""
    <div class="flex flex-col gap-0">
      <div class="flex flex-row gap-2 items-center">
        <p
          :if={@active_log_category_id == @category.id}
          class="h-[10px] w-[10px] bg-green-500 rounded-full"
        />

        <button
          class="w-[100%] h-[100%] h-[40px] rounded-md"
          id={"log-category-#{@category.id}"}
          phx-click="select_log_category"
          phx-value-log_category_id={@category.id}
          style={"background-color: #{@category.color_code};"}
        >
          <div class="flex gap-2 justify-center text-sm  md:text-base p-2 text-white items-center">
            <span>
              <%= @category.name %>
            </span>
            <span>
              <.counter_for_time_taken_by_current_task
                language={@language}
                category={@category}
                current_time={@current_time}
              />
            </span>
          </div>
        </button>
      </div>
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

  def counter_for_time_taken_by_current_task(assigns) do
    ~H"""
    <%= for log_entry <- @category.log_entries |> Enum.filter(fn x -> x.created_at |> DateTime.to_date == Date.utc_today  end)   do %>
      <p :if={log_entry.end_at == nil}>
        <%= Time.diff(Time.utc_now(), log_entry.start_at, :minute) |> minutes_to_hhmm() %>
      </p>
    <% end %>
    """
  end

  def minutes_to_hhmm(minutes) do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)

    # Format to ensure two digits for both hours and minutes
    formatted_time =
      :io_lib.format("~2..0B:~2..0B", [hours, remaining_minutes])
      |> IO.iodata_to_binary()

    "(#{formatted_time})"
  end

  def select_for_groups_and_project(assigns) do
    ~H"""
    <div class="flex flex-col mb-3 gap-1">
      <p>
        <%= @header_text %>
      </p>

      <div class="w-[100%] flex justify-between">
        <form phx-change="select_group" phx-submit="select_group" class="w-[48%] form-control">
          <p>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Select Group") %>
            <% end) %>
          </p>

          <select
            name="group_id"
            id="group_id"
            defa
            class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
          >
            <%= for {name , id} <- @groups do %>
              <option selected={id == @group.id} value={id}>
                <%= name %>
              </option>
            <% end %>
          </select>
        </form>

        <form phx-change="select_project" phx-submit="select_project" class=" w-[48%] form-control">
          <p>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Select Project") %>
            <% end) %>
          </p>
          <select
            name="project_id"
            id="project_id"
            defa
            class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
          >
            <%= for {name , id} <- @projects do %>
              <option selected={id == @project.id} value={id}>
                <%= name %>
              </option>
            <% end %>
          </select>
        </form>
      </div>
    </div>
    """
  end
end
