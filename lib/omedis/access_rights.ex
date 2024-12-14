defmodule Omedis.AccessRights do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Omedis.AccessRights.AccessRight
  end
end
