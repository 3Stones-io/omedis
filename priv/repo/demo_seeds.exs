import Omedis.Fixtures

alias Omedis.Accounts

bulk_create = fn module, list, upsert_identity ->
  list
  |> Stream.map(fn attrs ->
    module
    |> attrs_for()
    |> Map.merge(attrs)
  end)
  |> Ash.bulk_create(module, :create,
    authorize?: false,
    return_errors?: true,
    return_records?: true,
    sorted?: true,
    transaction: :all,
    upsert?: true,
    upsert_fields: [],
    upsert_identity: upsert_identity
  )
end

%{records: [user_1, user_2, user_3], status: :success} =
  bulk_create.(
    Accounts.User,
    [
      %{email: "user@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user2@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user3@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")}
    ],
    :unique_email
  )

%{records: [tenant_1, tenant_2], status: :success} =
  bulk_create.(
    Accounts.Tenant,
    [
      %{owner_id: user_1.id, slug: "demo-tenant"},
      %{owner_id: user_2.id, slug: "demo-tenant-2"}
    ],
    :unique_slug
  )

%{records: [group_1, group_2, group_3], status: :success} =
  bulk_create.(
    Accounts.Group,
    [
      %{name: "Demo Group", slug: "demo-group", tenant_id: tenant_1.id},
      %{name: "Demo Group 2", slug: "demo-group2", tenant_id: tenant_1.id},
      %{name: "Demo Group 3", slug: "demo-group3", tenant_id: tenant_2.id}
    ],
    :unique_slug_per_tenant
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupUser,
    [
      %{group_id: group_1.id, user_id: user_1.id},
      %{group_id: group_2.id, user_id: user_2.id},
      %{group_id: group_3.id, user_id: user_3.id}
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.AccessRight,
    [
      %{
        group_id: group_1.id,
        tenant_id: tenant_1.id,
        resource_name: "Project",
        read: true,
        write: true
      },
      %{
        group_id: group_2.id,
        tenant_id: tenant_2.id,
        resource_name: "Group",
        read: true,
        write: true
      },
      %{group_id: group_3.id, read: true, resource_name: "Tenant", tenant_id: tenant_2.id}
    ],
    nil
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.Project,
    [
      %{
        name: "Demo Project 1",
        tenant_id: tenant_1.id,
        position: "1"
      },
      %{
        name: "Demo Project 2",
        tenant_id: tenant_1.id,
        position: "2"
      },
      %{
        name: "Demo Project 3",
        tenant_id: tenant_2.id,
        position: "1"
      }
    ],
    :unique_name
  )
