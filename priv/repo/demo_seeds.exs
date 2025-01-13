import Omedis.Fixtures

alias Omedis.Accounts
alias Omedis.Groups
alias Omedis.Invitations
alias Omedis.Projects
alias Omedis.TimeTracking

require Ash.Query

bulk_create = fn module, list, opts ->
  list
  |> Stream.map(fn attrs ->
    module
    |> attrs_for(Keyword.get(opts, :tenant))
    |> Map.merge(attrs)
  end)
  |> Ash.bulk_create(
    module,
    :create,
    Keyword.merge(
      [
        authorize?: false,
        return_errors?: true,
        return_records?: true,
        sorted?: true,
        transaction: :all,
        upsert?: true,
        upsert_fields: []
      ],
      opts
    )
  )
end

sequential_create = fn module, list, opts ->
  opts = Keyword.merge([authorize?: false], opts)

  result =
    Enum.reduce_while(list, {:ok, []}, fn attrs, {:ok, acc} ->
      attrs =
        module
        |> attrs_for(Keyword.get(opts, :tenant))
        |> Map.merge(attrs)

      # Get the existence check keys
      existence_keys = Keyword.get(opts, :existence_check_keys, [])
      check_attrs = Map.take(attrs, existence_keys)

      # Build query for existence check
      query =
        module
        |> Ash.Query.new()
        |> Ash.Query.filter(^check_attrs)

      case existence_keys != [] &&
             Ash.exists?(query, tenant: Keyword.get(opts, :tenant), authorize?: false) do
        # Record exists, fetch it and add to accumulator
        true ->
          {:ok, [existing]} =
            Ash.read(query, authorize?: false, tenant: Keyword.get(opts, :tenant))

          {:cont, {:ok, [existing | acc]}}

        # Record doesn't exist or no existence check needed, create it
        false ->
          case Ash.create(module, attrs, opts) do
            {:ok, record} -> {:cont, {:ok, [record | acc]}}
            error -> {:halt, error}
          end
      end
    end)

  case result do
    {:ok, records} -> %{records: Enum.reverse(records), status: :success}
    error -> error
  end
end

get_organisation =
  fn owner_id ->
    Accounts.Organisation
    |> Ash.Query.filter(owner_id: owner_id)
    |> Ash.read_one!(authorize?: false)
  end

%{records: [user_1, user_2, user_3], status: :success} =
  sequential_create.(
    Accounts.User,
    [
      %{email: "user@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user2@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")},
      %{email: "user3@demo.com", hashed_password: Bcrypt.hash_pwd_salt("password")}
    ],
    existence_check_keys: [:email]
  )

organisation_1 = get_organisation.(user_1.id)
organisation_2 = get_organisation.(user_2.id)

%{records: [group_1, group_2], status: :success} =
  bulk_create.(
    Groups.Group,
    [
      %{name: "Demo Group"},
      %{name: "Demo Group 2"}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: [group_3], status: :success} =
  bulk_create.(
    Groups.Group,
    [
      %{name: "Demo Group 3"}
    ],
    tenant: organisation_2,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Groups.GroupMembership,
    [
      %{group_id: group_1.id, user_id: user_1.id},
      %{group_id: group_2.id, user_id: user_2.id}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_group_membership
  )

%{records: _records, status: :success} =
  bulk_create.(
    Groups.GroupMembership,
    [
      %{group_id: group_3.id, user_id: user_3.id}
    ],
    tenant: organisation_2,
    upsert_identity: :unique_group_membership
  )

%{records: [project_1, project_2], status: :success} =
  bulk_create.(
    Projects.Project,
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
    tenant: organisation_1,
    upsert_fields: [:name, :position],
    upsert_identity: :unique_name
  )

%{records: _records, status: :success} =
  bulk_create.(
    Projects.Project,
    [
      %{
        name: "Demo Project 3",
        position: "2"
      }
    ],
    tenant: organisation_2,
    upsert_fields: [:name, :position],
    upsert_identity: :unique_name
  )

activities =
  for i <- 1..30 do
    %{
      name: "Demo Activity #{i}",
      group_id: if(rem(i, 2) == 0, do: group_1.id, else: group_2.id),
      project_id: if(rem(i, 2) == 0, do: project_1.id, else: project_2.id)
    }
  end

%{records: _records, status: :success} =
  sequential_create.(
    TimeTracking.Activity,
    activities,
    tenant: organisation_1,
    existence_check_keys: [:slug, :group_id]
  )

%{records: [invitation_1 | _rest], status: :success} =
  bulk_create.(
    Invitations.Invitation,
    [
      %{creator_id: user_1.id},
      %{creator_id: user_2.id}
    ],
    tenant: organisation_1
  )

%{records: _records, status: :success} =
  bulk_create.(
    Invitations.InvitationGroup,
    [
      %{invitation_id: invitation_1.id, group_id: group_1.id}
    ],
    tenant: organisation_1
  )
