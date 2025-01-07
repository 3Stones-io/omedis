defmodule Omedis.Groups do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Omedis.Groups.Group do
      define :create_group, action: :create
      define :destroy_group, action: :destroy
      define :update_group, action: :update
      define :get_group_by_id, get_by: [:id], action: :read

      define :get_group_by_organisation_id,
        action: :by_organisation_id

      define :get_group_by_slug, get_by: [:slug], action: :read
    end

    resource Omedis.Groups.GroupMembership do
      define :create_group_membership, args: [:group_id, :user_id], action: :create
      define :get_group_membership_by_id, get_by: [:id], action: :read
      define :destroy_group_membership, action: :destroy
    end
  end
end
