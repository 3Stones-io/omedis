defmodule Omedis.AccessRights do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Omedis.AccessRights.AccessRight do
      define :create_access_right, action: :create
    end
  end
end
