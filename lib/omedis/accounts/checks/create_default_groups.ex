defmodule Omedis.Accounts.Changes.CreateDefaultGroups do
  @moduledoc """
  Creates the following default groups when a new organisation is created.

  - `Administrators` group with full access to select resources.
  - `Users` group with just create and read access to `LogEntry` resource, and read-only access to other select resources.

  The organisation owner is automatically added to the `Administrators` group.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts

  @admin_full_access_resources [
    "AccessRight",
    "Activity",
    "Group",
    "GroupMembership",
    "Event",
    "Invitation",
    "InvitationGroup",
    "LogEntry",
    "Organisation",
    "Project",
    "Token"
  ]

  @admin_read_only_resources ["User"]

  @user_read_only_resources [
    "AccessRight",
    "Activity",
    "Group",
    "GroupMembership",
    "Event",
    "Invitation",
    "InvitationGroup",
    "Organisation",
    "Project",
    "Token",
    "User"
  ]

  @user_create_resources ["LogEntry"]

  @impl true
  def change(changeset, _, %{actor: nil}), do: changeset

  def change(changeset, _, context) do
    actor = Map.get(context, :actor)

    Ash.Changeset.after_action(changeset, fn _changeset, organisation ->
      opts = [actor: actor, authorize?: false, tenant: organisation]
      administrators_group = create_admins_group(organisation, opts)
      users_group = create_users_group(organisation, opts)
      create_admin_access_rights(administrators_group, opts)
      create_user_access_rights(users_group, opts)

      {:ok, organisation}
    end)
  end

  defp create_admins_group(organisation, opts) do
    {:ok, administrators_group} =
      Accounts.Group.create(
        %{
          name: "Administrators",
          slug: "administrators",
          user_id: organisation.owner_id
        },
        opts
      )

    {:ok, _} =
      Accounts.GroupMembership.create(
        %{
          group_id: administrators_group.id,
          user_id: organisation.owner_id
        },
        opts
      )

    administrators_group
  end

  defp create_users_group(organisation, opts) do
    {:ok, users_group} =
      Accounts.Group.create(
        %{
          name: "Users",
          slug: "users",
          user_id: organisation.owner_id
        },
        opts
      )

    users_group
  end

  defp create_admin_access_rights(group, opts) do
    for resource_name <- @admin_full_access_resources do
      {:ok, _} =
        Accounts.AccessRight.create(
          %{
            create: true,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: true,
            write: true
          },
          opts
        )
    end

    for resource_name <- @admin_read_only_resources do
      {:ok, _} =
        Accounts.AccessRight.create(
          %{
            create: false,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            write: false
          },
          opts
        )
    end
  end

  defp create_user_access_rights(group, opts) do
    for resource_name <- @user_read_only_resources do
      {:ok, _} =
        Accounts.AccessRight.create(
          %{
            create: false,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            write: false
          },
          opts
        )
    end

    for resource_name <- @user_create_resources do
      {:ok, _} =
        Accounts.AccessRight.create(
          %{
            create: true,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            write: false
          },
          opts
        )
    end
  end
end
