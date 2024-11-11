defmodule Omedis.Accounts.Changes.CreateDefaultGroups do
  @moduledoc """
  Creates the following default groups when a new organisation is created.

  - `Administrators` group with full access to all resources.
  - `Employees` group with just create and read access to `LogEntry` resource, and read-only access to all resources.

  The organisation owner is automatically added to the `Administrators` group.
  """

  use Ash.Resource.Change

  alias Omedis.Accounts

  @impl true
  def change(changeset, _, _) do
    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      organisation = Ash.load!(record, :owner)
      opts = [actor: organisation.owner, tenant: organisation]

      [administrators_group, employees_group] = create_default_groups(organisation, opts)
      create_admin_access_rights(administrators_group, opts)
      create_employee_access_rights(employees_group, opts)

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

    {:ok, employees_group} =
      Accounts.Group.create(
        %{
          name: "Employees",
          slug: "employees",
          user_id: organisation.owner_id
        },
        opts
      )

    [administrators_group, employees_group]
  end

  defp create_admin_access_rights(group, opts) do
    {:ok, _} =
      Accounts.AccessRight.create(
        %{
          create: true,
          group_id: group.id,
          read: true,
          resource_name: "*",
          update: true,
          write: true
        },
        opts
      )
  end

  defp create_employee_access_rights(group, opts) do
    {:ok, _} =
      Accounts.AccessRight.create(
        %{
          create: false,
          group_id: group.id,
          read: true,
          resource_name: "*",
          update: false,
          write: false
        },
        opts
      )

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
