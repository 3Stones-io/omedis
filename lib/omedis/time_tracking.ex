defmodule Omedis.TimeTracking do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Omedis.TimeTracking.Activity
    resource Omedis.TimeTracking.Event
  end
end
