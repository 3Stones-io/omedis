defmodule Omedis.TimeTracking do
  @moduledoc false
  use Ash.Domain

  require Ash.Query

  alias Omedis.TimeTracking.Activity

  resources do
    resource Omedis.TimeTracking.Activity
    resource Omedis.TimeTracking.Event
  end

  @github_issue_color_codes [
    "#1f77b4",
    "#ff7f0e",
    "#2ca02c",
    "#d62728",
    "#9467bd",
    "#8c564b",
    "#e377c2",
    "#7f7f7f",
    "#bcbd22",
    "#17becf"
  ]

  def move_activity_up(activity, opts \\ []) do
    case activity.position do
      1 ->
        {:ok, activity}

      _ ->
        Activity.update_position(activity, %{position: activity.position - 1}, opts)
    end
  end

  def move_activity_down(activity, opts \\ []) do
    last_position = get_max_position_by_group_id(activity.group_id, opts)

    case activity.position do
      ^last_position ->
        {:ok, activity}

      _ ->
        Activity.update_position(activity, %{position: activity.position + 1}, opts)
    end
  end

  def select_unused_color_code(organisation) do
    existing_color_codes = get_color_code_for_an_organisation(organisation)

    unused_color_code =
      @github_issue_color_codes
      |> Enum.filter(fn color_code -> color_code not in existing_color_codes end)
      |> Enum.random()

    case unused_color_code do
      nil -> Enum.random(@github_issue_color_codes)
      color_code -> color_code
    end
  end

  defp get_max_position_by_group_id(group_id, opts) do
    Activity
    |> Ash.Query.filter(group_id: group_id)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.Query.select([:position])
    |> Ash.read!(opts)
    |> Enum.at(0)
    |> case do
      nil -> 0
      record -> record.position
    end
  end

  defp get_color_code_for_an_organisation(organisation) do
    Activity
    |> Ash.Query.select([:color_code])
    |> Ash.read!(authorize?: false, tenant: organisation)
    |> Enum.map(& &1.color_code)
  end
end
