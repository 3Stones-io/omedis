defmodule Omedis.AccessRights do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Omedis.AccessRights.AccessRight do
      define :read_access_right, action: :read
      define :update_access_right, action: :update
      define :destroy_access_right, action: :destroy
    end
  end
end
