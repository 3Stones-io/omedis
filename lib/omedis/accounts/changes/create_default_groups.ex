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
      organisation =
        Ash.load!(record, :owner)

      create_default_groups_and_access_rights(organisation)

      {:ok, organisation}
    end)
  end

  defp create_default_groups_and_access_rights(organisation) do
    opts = [actor: organisation.owner, tenant: organisation]

    {:ok, administrators_group} =
      Accounts.Group.create(
        %{
          name: "Administrators",
          slug: "administrators",
          organisation_id: organisation.id,
          user_id: organisation.owner_id
        },
        opts
      )

    {:ok, employees_group} =
      Accounts.Group.create(
        %{
          name: "Employees",
          slug: "employees",
          organisation_id: organisation.id,
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

    create_admin_access_rights(administrators_group, opts)
    create_employee_access_rights(employees_group, opts)
  end

  defp create_admin_access_rights(group, opts) do
    Accounts.AccessRight.create(
      %{
        create: true,
        group_id: group.id,
        read: true,
        resource_name: "*",
        organisation_id: opts[:tenant].id,
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
          organisation_id: opts[:tenant].id,
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
          organisation_id: opts[:tenant].id,
          update: false,
          write: false
        },
        opts
      )
  end
end
