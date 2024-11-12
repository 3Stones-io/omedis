defmodule Omedis.Accounts.Changes.CreateDefaultGroups do
  @moduledoc """
  Creates the following default groups when a new organisation is created.

  - `Administrators` group with full access to select resources.
  - `Users` group with just create and read access to `LogEntry` resource, and read-only access to other select resources.

  The organisation owner is automatically added to the `Administrators` group.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts

  @select_resources [
    "AccessRight",
    "Activity",
    "Group",
    "GroupMembership",
    "Invitation",
    "InvitationGroup",
    "LogEntry",
    "Organisation",
    "Project",
    "Token"
  ]

  @impl true
  def change(changeset, _, _) do
    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      organisation = Ash.load!(record, :owner)
      opts = [actor: organisation.owner, tenant: organisation]

      [administrators_group, users_group] = create_default_groups(organisation, opts)
      create_admin_access_rights(administrators_group, opts)
      create_employee_access_rights(users_group, opts)

      {:ok, organisation}
    end)
  end

  defp create_default_groups(organisation, opts) do
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

    {:ok, users_group} =
      Accounts.Group.create(
        %{
          name: "Users",
          slug: "users",
          user_id: organisation.owner_id
        },
        opts
      )

    [administrators_group, users_group]
  end

  defp create_admin_access_rights(group, opts) do
    Enum.each(@select_resources, fn resource_name ->
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
    end)

    # # Create more fine-grained access rights for the User resource
    {:ok, _} =
      Accounts.AccessRight.create(
        %{
          create: false,
          group_id: group.id,
          read: true,
          resource_name: "User",
          update: false,
          write: false
        },
        opts
      )
  end

  defp create_employee_access_rights(group, opts) do
    resources =
      @select_resources
      |> Kernel.++(["User"])
      |> Kernel.--(["LogEntry"])

    Enum.each(resources, fn resource_name ->
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
    end)

    # Create more fine-grained access right for the LogEntry resource
    {:ok, _} =
      Accounts.AccessRight.create(
        %{
          create: true,
          group_id: group.id,
          read: true,
          resource_name: "LogEntry",
          update: false,
          write: false
        },
        opts
      )
  end
end
