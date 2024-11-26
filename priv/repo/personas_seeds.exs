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

%{records: [denis, heidi, _fatima, _ben, _sarah, _lena, _tim, _anna, _marc], status: :success} =
  bulk_create.(
    Accounts.User,
    nil,
    [
      # Spitex Bemeda
      %{
        email: "denis.gojak@spitex-bemeda.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Denis",
        last_name: "Gojak"
      },
      %{
        email: "heidi@spitex-bemeda.ch",
        hashed_password: Bcrypt.hash_pwd_salt("secure_heidi")
      },
      %{
        email: "fatima.khan@spitex-bemeda.ch",
        hashed_password: Bcrypt.hash_pwd_salt("fatima123"),
        first_name: "Fatima",
        last_name: "Khan"
      },
      # ASA Security
      %{
        email: "ben.hall@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("bensecure"),
        first_name: "Ben",
        last_name: "Hall"
      },
      %{
        email: "sarah.jones@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("sarah2024"),
        first_name: "Sarah",
        last_name: "Jones"
      },
      %{
        email: "lena.meyer@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("meyerpass"),
        first_name: "Lena",
        last_name: "Meyer"
      },
      # 3Stones
      %{
        email: "tim.davis@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("timrocks"),
        first_name: "Tim",
        last_name: "Davis"
      },
      %{
        email: "anna.wilson@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("anna456"),
        first_name: "Anna",
        last_name: "Wilson"
      },
      %{
        email: "marc.brown@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("marc789"),
        first_name: "Marc",
        last_name: "Brown"
      }
    ],
    :unique_email
  )

%{records: [organisation_1, organisation_2, organisation_3], status: :success} =
  bulk_create.(
    Accounts.Organisation,
    nil,
    [
      %{owner_id: denis.id, name: "Spitex Bemeda", slug: "spitex-bemeda"},
      %{owner_id: denis.id, name: "ASA Security", slug: "asa-security"},
      %{owner_id: denis.id, name: "3Stones", slug: "3stones"}
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

# Add groups for other organisations
%{records: [security_group], status: :success} =
  bulk_create.(
    Accounts.Group,
    organisation_2,
    [
      %{name: "Security Team", slug: "security-team"}
    ],
    :unique_slug_per_organisation
  )

%{records: [dev_group], status: :success} =
  bulk_create.(
    Accounts.Group,
    organisation_3,
    [
      %{name: "Development Team", slug: "dev-team"}
    ],
    :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupMembership,
    organisation_1,
    [
      %{group_id: group_1.id, user_id: denis.id},
      %{group_id: group_2.id, user_id: heidi.id}
    ],
    :unique_group_membership
  )

# Projects for each organization
%{records: [medical_support, security_operations, software_development], status: :success} =
  bulk_create.(
    Accounts.Project,
    nil,
    [
      %{organisation_id: organisation_1.id, name: "Medical Support", position: "1"},
      %{organisation_id: organisation_2.id, name: "Security Operations", position: "2"},
      %{organisation_id: organisation_3.id, name: "Software Development", position: "3"}
    ],
    :unique_name
  )

# Activities for each organization
%{records: _records, status: :success} =
  bulk_create.(
    Accounts.Activity,
    organisation_1,
    [
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Visit Patient",
        description: "Provide medical care to a patient.",
        color_code: "#FF0000",
        is_default: true
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Drive to Patient",
        description: "Travel to a patient's home.",
        color_code: "#00FF00",
        is_default: false
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Administer Medication",
        description: "Provide prescribed medicines.",
        color_code: "#0000FF",
        is_default: false
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Follow-Up Visit",
        description: "Check on patient's recovery.",
        color_code: "#FF00FF",
        is_default: false
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Health Assessment",
        description: "Perform routine health check-ups.",
        color_code: "#FFFF00",
        is_default: false
      }
    ],
    :unique_slug
  )

%{records: _security_activities, status: :success} =
  bulk_create.(
    Accounts.Activity,
    organisation_2,
    [
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Surveillance - Building",
        description: "Monitor building security.",
        color_code: "#FF0000",
        is_default: true
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Drive to Building",
        description: "Travel to site for security check.",
        color_code: "#00FF00",
        is_default: false
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Incident Reporting",
        description: "Document and report incidents.",
        color_code: "#0000FF",
        is_default: false
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Guard Assignment",
        description: "Assign guards to specific areas.",
        color_code: "#FF00FF",
        is_default: false
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Alarm Response",
        description: "Respond to security alarms.",
        color_code: "#FFFF00",
        is_default: false
      }
    ],
    :unique_activity_name
  )

%{records: _software_activities, status: :success} =
  bulk_create.(
    Accounts.Activity,
    organisation_3,
    [
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "UI Design",
        description: "Design user interfaces.",
        color_code: "#FF0000",
        is_default: true
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Modeling",
        description: "Create system models and diagrams.",
        color_code: "#00FF00",
        is_default: false
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Code Review",
        description: "Review code for quality and issues.",
        color_code: "#0000FF",
        is_default: false
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Talking to Devs",
        description: "Communicate requirements with developers.",
        color_code: "#FF00FF",
        is_default: false
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Testing Features",
        description: "Perform testing on developed features.",
        color_code: "#FFFF00",
        is_default: false
      }
    ],
    :unique_activity_name
  )
