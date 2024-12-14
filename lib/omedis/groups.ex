defmodule Omedis.Groups do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Omedis.Groups.Group
    resource Omedis.Groups.GroupMembership
  end
end
