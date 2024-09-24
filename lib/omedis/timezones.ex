defmodule Tenx.Timezones do
  @moduledoc """
  This module contains a list of timezones
  """
  def all_timezones do
    [
      %{"name" => "GMT", "difference" => 0},
      %{"name" => "UTC", "difference" => 0},
      %{"name" => "America/New_York", "difference" => -4},
      %{"name" => "America/Los_Angeles", "difference" => -7},
      %{"name" => "Europe/London", "difference" => 1},
      %{"name" => "Europe/Berlin", "difference" => 2},
      %{"name" => "Asia/Tokyo", "difference" => 9},
      %{"name" => "Asia/Shanghai", "difference" => 8},
      %{"name" => "Africa/Lagos", "difference" => 1},
      %{"name" => "Africa/Nairobi", "difference" => 3},
      %{"name" => "Africa/Cairo", "difference" => 2},
      %{"name" => "Africa/Johannesburg", "difference" => 2},
      %{"name" => "Africa/Algiers", "difference" => 1},
      %{"name" => "Pacific/Honolulu", "difference" => -10},
      %{"name" => "Australia/Sydney", "difference" => 10},
      %{"name" => "America/Chicago", "difference" => -5},
      %{"name" => "America/Sao_Paulo", "difference" => -3},
      %{"name" => "Asia/Dubai", "difference" => 4},
      %{"name" => "Europe/Moscow", "difference" => 3}
    ]
  end
end
