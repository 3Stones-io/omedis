import Omedis.Fixtures

require Ash.Query

alias Omedis.AccessRights
alias Omedis.Accounts
alias Omedis.DemoSeeds

defmodule Omedis.DemoSeeds do
  def get_organisation_by_owner_id(owner_id) do
    Accounts.Organisation
    |> Ash.Query.filter(owner_id: owner_id)
    |> Ash.read_one!(authorize?: false)
  end
end

bulk_create = fn module, organisation, list, upsert_identity ->
  list
  |> Stream.map(fn attrs ->
    module
    |> attrs_for(organisation)
    |> Map.merge(attrs)
  end)
  |> Ash.bulk_create(module, :create,
    authorize?: false,
    return_errors?: true,
    return_records?: true,
    sorted?: true,
    tenant: organisation,
    transaction: :all,
    upsert?: true,
    upsert_fields: [],
    upsert_identity: upsert_identity,
    domain: Ash.Resource.Info.domain(module)
  )
end

%{records: [user_1, user_2, user_3], status: :success} =
  bulk_create.(
    Accounts.User,
    nil,
    [
      %{email: "user@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user2@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user3@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")}
    ],
    :unique_email
  )

organisation_1 = DemoSeeds.get_organisation_by_owner_id(user_1.id)

%{records: [group_1, group_2], status: :success} =
  bulk_create.(
    Omedis.Groups.Group,
    organisation_1,
    [
      %{name: "Demo Group", slug: "demo-group"},
      %{name: "Demo Group 2", slug: "demo-group2"}
    ],
    :unique_slug_per_organisation
  )

organisation_2 = DemoSeeds.get_organisation_by_owner_id(user_2.id)

%{records: [group_3], status: :success} =
  bulk_create.(
    Omedis.Groups.Group,
    organisation_2,
    [
      %{name: "Demo Group 3", slug: "demo-group3"}
    ],
    :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Omedis.Groups.GroupMembership,
    organisation_1,
    [
      %{group_id: group_1.id, user_id: user_1.id},
      %{group_id: group_2.id, user_id: user_2.id}
    ],
    :unique_group_membership
  )

%{records: _records, status: :success} =
  bulk_create.(
    Omedis.Groups.GroupMembership,
    organisation_2,
    [
      %{group_id: group_3.id, user_id: user_3.id}
    ],
    :unique_group_membership
  )

%{records: _records, status: :success} =
  bulk_create.(
    AccessRights.AccessRight,
    organisation_1,
    [
      %{
        group_id: group_1.id,
        resource_name: "Project",
        read: true,
        update: true,
        create: true,
        destroy: true
      }
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    AccessRights.AccessRight,
    organisation_1,
    [
      %{
        group_id: group_2.id,
        resource_name: "Group",
        read: true,
        update: true,
        create: true,
        destroy: true
      },
      %{
        group_id: group_1.id,
        resource_name: "Group",
        read: true,
        update: true,
        create: true,
        destroy: true
      },
      %{
        group_id: group_2.id,
        resource_name: "Activity",
        read: true,
        update: true,
        create: true,
        destroy: true
      },
      %{
        group_id: group_1.id,
        resource_name: "Activity",
        read: true,
        update: true,
        create: true,
        destroy: true
      },
      %{
        group_id: group_2.id,
        resource_name: "Event",
        read: true,
        update: true,
        create: true,
        destroy: true
      },
      %{
        group_id: group_1.id,
        resource_name: "Invitation",
        read: true,
        update: true,
        create: true,
        destroy: true
      }
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    AccessRights.AccessRight,
    organisation_1,
    [
      %{
        group_id: group_1.id,
        read: true,
        resource_name: "Organisation"
      }
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    AccessRights.AccessRight,
    organisation_2,
    [
      %{
        group_id: group_3.id,
        read: true,
        resource_name: "Organisation"
      }
    ],
    nil
  )

%{records: [project_1, project_2], status: :success} =
  bulk_create.(
    Accounts.Project,
    organisation_1,
    [
      %{
        name: "Demo Project 1",
        position: "3"
      },
      %{
        name: "Demo Project 2",
        position: "4"
      }
    ],
    :unique_name
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.Project,
    organisation_2,
    [
      %{
        name: "Demo Project 3",
        position: "2"
      }
    ],
    :unique_name
  )

%{records: _records, status: :success} =
  bulk_create.(
    TimeTracking.Activity,
    organisation_1,
    [
      %{
        group_id: group_1.id,
        project_id: project_1.id,
        name: "Demo Activity 1"
      },
      %{
        group_id: group_2.id,
        project_id: project_2.id,
        name: "Demo Activity 2"
      }
    ],
    :unique_slug
  )

%{records: [invitation_1 | _rest], status: :success} =
  bulk_create.(
    Omedis.Invitations.Invitation,
    organisation_1,
    [
      %{creator_id: user_1.id},
      %{creator_id: user_2.id}
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Omedis.Invitations.InvitationGroup,
    organisation_1,
    [
      %{invitation_id: invitation_1.id, group_id: group_1.id}
    ],
    nil
  )
