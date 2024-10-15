defmodule Omedis.Accounts.Notifiers do
  @moduledoc false
  use Ash.Notifier

  @impl true
  def notify(%{resource: Omedis.Accounts.LogCategory, action: %{name: name}})
      when name in [:decrement_position, :increment_position] do
    Phoenix.PubSub.broadcast(Omedis.PubSub, "log_category_positions_updated", "updated_positions")
    :ok
  end

  def notify(_args) do
    :ok
  end
end
