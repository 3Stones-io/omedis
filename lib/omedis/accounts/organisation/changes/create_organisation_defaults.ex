defmodule Omedis.Accounts.Organisation.Changes.CreateOrganisationDefaults do
  @moduledoc """
  Creates the following default groups when a new organisation is created.

  - `Administrators` group with full access to select resources.
  - `Users` group with just create and read access to `Event` resource, and read-only access to other select resources.

  The organisation owner is automatically added to the `Administrators` group.

  Also creates a project called "Project 1" and an activity called "Miscellaneous" in the "Users" group.
  """

  use Ash.Resource.Change

  alias Omedis.AccessRights
  alias Omedis.Groups
  alias Omedis.Projects
  alias Omedis.TimeTracking

  @admin_full_access_resources [
    "AccessRight",
    "Activity",
    "Event",
    "Group",
    "GroupMembership",
    "Invitation",
    "InvitationGroup",
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
    "Invitation",
    "InvitationGroup",
    "Organisation",
    "Project",
    "Token",
    "User"
  ]

  @user_create_resources ["Event"]

  @impl true
  def change(changeset, _, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, organisation ->
      opts = [authorize?: false, tenant: organisation]
      administrators_group = create_admins_group(organisation, opts)
      users_group = create_users_group(organisation, opts)
      create_admin_access_rights(administrators_group, opts)
      create_user_access_rights(users_group, opts)
      project = create_project(organisation, opts)
      create_activity(project, users_group, opts)

      {:ok, organisation}
    end)
  end

  defp create_admins_group(organisation, opts) do
    {:ok, administrators_group} =
      Groups.create_group(
        %{
          name: "Administrators",
          user_id: organisation.owner_id
        },
        opts ++
          [
            upsert?: true,
            upsert_identity: :unique_slug_per_organisation
          ]
      )

    {:ok, _} =
      Groups.create_group_membership(
        %{
          group_id: administrators_group.id,
          user_id: organisation.owner_id
        },
        opts ++
          [
            upsert?: true,
            upsert_identity: :unique_group_membership
          ]
      )

    administrators_group
  end

  defp create_users_group(organisation, opts) do
    {:ok, users_group} =
      Groups.create_group(
        %{
          name: "Users",
          user_id: organisation.owner_id
        },
        opts ++
          [
            upsert?: true,
            upsert_identity: :unique_slug_per_organisation
          ]
      )

    users_group
  end

  defp create_admin_access_rights(group, opts) do
    for resource_name <- @admin_full_access_resources do
      {:ok, _} =
        AccessRights.create_access_right(
          %{
            create: true,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: true,
            destroy: true
          },
          opts
        )
    end

    for resource_name <- @admin_read_only_resources do
      {:ok, _} =
        AccessRights.create_access_right(
          %{
            create: false,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            destroy: false
          },
          opts
        )
    end
  end

  defp create_user_access_rights(group, opts) do
    for resource_name <- @user_read_only_resources do
      {:ok, _} =
        AccessRights.create_access_right(
          %{
            create: false,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            destroy: false
          },
          opts
        )
    end

    for resource_name <- @user_create_resources do
      {:ok, _} =
        AccessRights.create_access_right(
          %{
            create: true,
            group_id: group.id,
            read: true,
            resource_name: resource_name,
            update: false,
            destroy: false
          },
          opts
        )
    end
  end

  defp create_project(organisation, actor) do
    {:ok, project} =
      Projects.create_project(
        %{
          name: "Project 1",
          position: "1",
          organisation_id: organisation.id
        },
        actor: actor,
        tenant: organisation,
        authorize?: false,
        upsert?: true,
        upsert_identity: :unique_name
      )

    project
  end

  defp create_activity(project, users_group, opts) do
    if !fetch_default_activity(opts) do
      {:ok, _} =
        TimeTracking.create_activity(
          %{
            name: "Miscellaneous",
            group_id: users_group.id,
            project_id: project.id,
            is_default: true,
            color_code: "#808080"
          },
          opts
        )
    end
  end

  defp fetch_default_activity(opts) do
    TimeTracking.Activity
    |> Ash.Query.filter(name: "Miscellaneous")
    |> Ash.read_one!(opts)
  end
end
