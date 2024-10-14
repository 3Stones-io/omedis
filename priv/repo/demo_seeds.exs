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

%{records: [user_1, user_2], status: :success} =
  bulk_create.(
    Accounts.User,
    [
      %{email: "user@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user2@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")}
    ],
    :unique_email
  )

%{records: [tenant_1 | _rest], status: :success} =
  bulk_create.(
    Accounts.Tenant,
    [
      %{owner_id: user_1.id, slug: "demo-tenant"},
      %{owner_id: user_2.id, slug: "demo-tenant-2"}
    ],
    :unique_slug
  )

%{records: [group_1, group_2 | _rest], status: :success} =
  bulk_create.(
    Accounts.Group,
    [
      %{name: "Demo Group", slug: "demo-group", tenant_id: tenant_1.id},
      %{name: "Demo Group 2", slug: "demo-group2", tenant_id: tenant_1.id}
    ],
    :unique_slug_per_tenant
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupUser,
    [
      %{group_id: group_1.id, user_id: user_1.id},
      %{group_id: group_2.id, user_id: user_2.id}
    ],
    nil
  )
