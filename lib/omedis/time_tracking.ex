defmodule Omedis.TimeTracking do
  @moduledoc false
  use Ash.Domain

  require Ash.Query

  alias Omedis.TimeTracking.Activity

  resources do
    resource Omedis.TimeTracking.Activity do
      define :create_activity, action: :create
      define :get_activities_by_group_id_and_project_id, action: :by_group_id_and_project_id
      define :get_activity_by_id, get_by: [:id], action: :read
      define :list_keyset_paginated_activities, action: :list_keyset_paginated
      define :list_paginated_activities, action: :list_paginated
      define :update_activity_position, action: :update_position
      define :update_activity, action: :update
    end

    resource Omedis.TimeTracking.Event do
      define :create_event, action: :create
      define :get_events_by_activity_today, action: :by_activity_today
      define :get_events_by_activity, action: :by_activity
      define :list_events, action: :read
      define :list_paginated_events, action: :list_paginated
      define :list_today_paginated_events, action: :list_paginated_today
      define :update_event, action: :update
    end
  end

  def move_activity_up(activity, opts \\ []) do
    case activity.position do
      1 ->
        {:ok, activity}

      _ ->
        update_activity_position(activity, %{position: activity.position - 1}, opts)
    end
  end

  def move_activity_down(activity, opts \\ []) do
    last_position = get_max_position_by_group_id(activity.group_id, opts)

    case activity.position do
      ^last_position ->
        {:ok, activity}

      _ ->
        update_activity_position(activity, %{position: activity.position + 1}, opts)
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
end
