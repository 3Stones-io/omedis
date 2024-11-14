defmodule Omedis.Accounts.Event.Calculations.CalculateDuration do
  @moduledoc """
  Calculates the duration of an event in minutes. Returns `nil` if the event has no end date.
  """

  use Ash.Resource.Calculation

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn
      %{dtend: nil} -> nil
      %{dtend: dtend, dtstart: dtstart} -> DateTime.diff(dtend, dtstart, :minute)
    end)
  end
end
