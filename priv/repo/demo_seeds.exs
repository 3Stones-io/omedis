import Omedis.Fixtures

alias Omedis.Accounts

require Ash.Query

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

sequential_create = fn module, list, opts ->
  opts = Keyword.merge([authorize?: false, upsert?: true], opts)

  result =
    Enum.reduce_while(list, {:ok, []}, fn attrs, {:ok, acc} ->
      attrs =
        module
        |> attrs_for(Keyword.get(opts, :tenant))
        |> Map.merge(attrs)

      # First check if record exists using the upsert_identity
      identity = Keyword.get(opts, :upsert_identity)
      identity_attrs = Map.take(attrs, Ash.Resource.Info.identity(module, identity).keys)

      query =
        module
        |> Ash.Query.new()
        |> Ash.Query.filter(^identity_attrs)

      case Ash.read(query, authorize?: false, tenant: Keyword.get(opts, :tenant)) do
        {:ok, %Ash.Page.Offset{results: [existing]}} ->
          {:cont, {:ok, [existing | acc]}}

        {:ok, [existing]} ->
          {:cont, {:ok, [existing | acc]}}

        {:ok, %Ash.Page.Offset{results: []}} ->
          case Ash.create(module, attrs, opts) do
            {:ok, record} -> {:cont, {:ok, [record | acc]}}
            error -> {:halt, error}
          end

        error ->
          {:halt, error}
      end
    end)

  case result do
    {:ok, records} -> %{records: Enum.reverse(records), status: :success}
    error -> error
  end
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
      %{group_id: group_2.id, user_id: user_2.id}
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
        update: true,
        create: true,
        destroy: true
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
    Accounts.AccessRight,
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

activities =
  for i <- 1..30 do
    %{
      group_id: if(rem(i, 2) == 0, do: group_1.id, else: group_2.id),
      project_id: if(rem(i, 2) == 0, do: project_1.id, else: project_2.id),
      name: "Demo Activity #{i}"
    }
  end

%{records: _records, status: :success} =
  sequential_create.(
    Accounts.Activity,
    activities,
    tenant: organisation_1,
    upsert_identity: :unique_slug
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
