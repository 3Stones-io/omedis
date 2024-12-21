defmodule Omedis.Accounts.Notifiers do
  @moduledoc false
  use Ash.Notifier

  @impl true
  def notify(%{resource: Omedis.TimeTracking.Activity, action: %{name: :update_position}}) do
    Phoenix.PubSub.broadcast(Omedis.PubSub, "activity_positions_updated", "updated_positions")
    :ok
  end

  def notify(_args) do
    :ok
  end
end
