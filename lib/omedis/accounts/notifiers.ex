defmodule Omedis.Accounts.Notifiers do
  use Ash.Notifier

  @impl true
  def notify(%{resource: Omedis.Accounts.LogCategory, action: %{type: :update}}) do
    Phoenix.PubSub.broadcast(Omedis.PubSub, "log_category_positions_updated", "updated_positions")
  end

  def notify(_args) do
    :ok
  end
end
