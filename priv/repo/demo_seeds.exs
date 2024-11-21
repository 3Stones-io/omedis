import Omedis.Fixtures

alias Omedis.Accounts

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
    upsert_identity: upsert_identity
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

%{records: [organisation_1, organisation_2], status: :success} =
  bulk_create.(
    Accounts.Organisation,
    nil,
    [
      %{owner_id: user_1.id, slug: "demo-organisation"},
      %{owner_id: user_2.id, slug: "demo-organisation-2"}
    ],
    :unique_slug
  )

%{records: [group_1, group_2], status: :success} =
  bulk_create.(
    Accounts.Group,
    organisation_1,
    [
      %{name: "Demo Group", slug: "demo-group"},
      %{name: "Demo Group 2", slug: "demo-group2"}
    ],
    :unique_slug_per_organisation
  )

%{records: [group_3], status: :success} =
  bulk_create.(
    Accounts.Group,
    organisation_2,
    [
      %{name: "Demo Group 3", slug: "demo-group3"}
    ],
    :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupMembership,
    organisation_1,
    [
      %{group_id: group_1.id, user_id: user_1.id},
      %{group_id: group_2.id, user_id: user_1.id}
    ],
    :unique_group_membership
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupMembership,
    organisation_2,
    [
      %{group_id: group_3.id, user_id: user_3.id}
    ],
    :unique_group_membership
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.AccessRight,
    organisation_1,
    [
      %{
        group_id: group_1.id,
        resource_name: "Project",
        read: true,
        write: true
      }
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.AccessRight,
    organisation_1,
    [
      %{
        group_id: group_2.id,
        resource_name: "Group",
        read: true,
        write: true
      },
      %{
        group_id: group_1.id,
        resource_name: "Group",
        read: true,
        write: true
      },
      %{
        group_id: group_2.id,
        resource_name: "Activity",
        read: true,
        write: true
      },
      %{
        group_id: group_1.id,
        resource_name: "Activity",
        read: true,
        write: true
      },
      %{
        group_id: group_2.id,
        resource_name: "Event",
        read: true,
        write: true
      }
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.AccessRight,
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
        position: "1"
      },
      %{
        name: "Demo Project 2",
        position: "2"
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
        position: "1"
      }
    ],
    :unique_name
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.Activity,
    organisation_1,
    [
      %{
        color_code: "#1f77b4",
        group_id: group_1.id,
        is_default: true,
        project_id: project_1.id,
        name: "Demo Activity 1"
      },
      %{
        color_code: "#ff7f0e",
        group_id: group_2.id,
        is_default: false,
        project_id: project_2.id,
        name: "Demo Activity 2"
      }
    ],
    :unique_slug
  )

%{records: [invitation_1 | _rest], status: :success} =
  bulk_create.(
    Accounts.Invitation,
    organisation_1,
    [
      %{creator_id: user_1.id},
      %{creator_id: user_2.id}
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.InvitationGroup,
    organisation_1,
    [
      %{invitation_id: invitation_1.id, group_id: group_1.id}
    ],
    nil
  )
