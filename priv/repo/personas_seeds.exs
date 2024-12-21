import Omedis.Fixtures

require Ash.Query

alias Omedis.Accounts

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
        {:ok, [existing]} ->
          {:cont, {:ok, [existing | acc]}}

        {:ok, []} ->
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

%{records: [denis, heidi, _fatima, ben, _sarah, _lena, tim, _anna, _marc], status: :success} =
  bulk_create.(
    Accounts.User,
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
    upsert_identity: :unique_email
  )

%{records: [organisation_1, organisation_2, organisation_3], status: :success} =
  bulk_create.(
    Accounts.Organisation,
    [
      %{owner_id: denis.id, name: "Spitex Bemeda", slug: "spitex-bemeda"},
      %{owner_id: denis.id, name: "ASA Security", slug: "asa-security"},
      %{owner_id: denis.id, name: "3Stones", slug: "3stones"}
    ],
    upsert_identity: :unique_slug
  )

%{records: [group_1, group_2], status: :success} =
  bulk_create.(
    Accounts.Group,
    [
      %{name: "Demo Group", slug: "demo-group"},
      %{name: "Demo Group 2", slug: "demo-group2"}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: [security_group], status: :success} =
  bulk_create.(
    Accounts.Group,
    [
      %{name: "Security Team", slug: "security-team"}
    ],
    tenant: organisation_2,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: [dev_group], status: :success} =
  bulk_create.(
    Accounts.Group,
    [
      %{name: "Development Team", slug: "dev-team"}
    ],
    tenant: organisation_3,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Accounts.GroupMembership,
    [
      %{group_id: group_1.id, user_id: denis.id},
      %{group_id: group_2.id, user_id: heidi.id}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_group_membership
  )

%{records: [medical_support, _frau_schmidt, _herr_meier], status: :success} =
  bulk_create.(
    Projects.Project,
    [
      %{organisation_id: organisation_1.id, name: "Medical Support", position: "1"},
      %{organisation_id: organisation_1.id, name: "Frau Schmidt", position: "2"},
      %{organisation_id: organisation_1.id, name: "Herr Meier", position: "3"}
    ],
    tenant: organisation_1,
    upsert_fields: [:name],
    upsert_identity: :unique_name
  )

%{records: [security_operations], status: :success} =
  bulk_create.(
    Projects.Project,
    [
      %{organisation_id: organisation_2.id, name: "Security Operations", position: "1"}
    ],
    tenant: organisation_2,
    upsert_fields: [:name],
    upsert_identity: :unique_name
  )

%{records: [software_development], status: :success} =
  bulk_create.(
    Projects.Project,
    [
      %{organisation_id: organisation_3.id, name: "Software Development", position: "1"}
    ],
    tenant: organisation_3,
    upsert_fields: [:name],
    upsert_identity: :unique_name
  )

%{
  records: [
    visit_patient,
    _drive_to_patient,
    administer_medication,
    follow_up_visit,
    health_assessment
  ],
  status: :success
} =
  sequential_create.(
    Accounts.Activity,
    [
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Visit Patient",
        color_code: "#FF0000",
        is_default: true,
        slug: "visit-patient"
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Drive to Patient",
        color_code: "#00FF00",
        is_default: false,
        slug: "drive-to-patient"
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Administer Medication",
        color_code: "#0000FF",
        is_default: false,
        slug: "administer-medication"
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Follow-Up Visit",
        color_code: "#FF00FF",
        is_default: false,
        slug: "follow-up-visit"
      },
      %{
        group_id: group_1.id,
        project_id: medical_support.id,
        name: "Health Assessment",
        color_code: "#FFFF00",
        is_default: false,
        slug: "health-assessment"
      }
    ],
    tenant: organisation_1,
    upsert_identity: :unique_slug
  )

%{
  records: [
    surveillance_building,
    _drive_to_building,
    _incident_reporting,
    _guard_assignment,
    _alarm_response
  ],
  status: :success
} =
  sequential_create.(
    Accounts.Activity,
    [
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Surveillance - Building",
        color_code: "#FF0000",
        is_default: true,
        slug: "surveillance-building"
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Drive to Building",
        color_code: "#00FF00",
        is_default: false,
        slug: "drive-to-building"
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Incident Reporting",
        color_code: "#0000FF",
        is_default: false,
        slug: "incident-reporting"
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Guard Assignment",
        color_code: "#FF00FF",
        is_default: false,
        slug: "guard-assignment"
      },
      %{
        group_id: security_group.id,
        project_id: security_operations.id,
        name: "Alarm Response",
        color_code: "#FFFF00",
        is_default: false,
        slug: "alarm-response"
      }
    ],
    tenant: organisation_2,
    upsert_fields: [:slug, :group_id],
    upsert_identity: :unique_slug
  )

%{
  records: [ui_design, _modeling, _code_review, _talking_to_devs, _testing_features],
  status: :success
} =
  sequential_create.(
    Accounts.Activity,
    [
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "UI Design",
        color_code: "#FF0000",
        is_default: true,
        slug: "ui-design"
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Modeling",
        color_code: "#00FF00",
        is_default: false,
        slug: "modeling"
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Code Review",
        color_code: "#0000FF",
        is_default: false,
        slug: "code-review"
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Talking to Devs",
        color_code: "#FF00FF",
        is_default: false,
        slug: "talking-to-devs"
      },
      %{
        group_id: dev_group.id,
        project_id: software_development.id,
        name: "Testing Features",
        color_code: "#FFFF00",
        is_default: false,
        slug: "testing-features"
      }
    ],
    tenant: organisation_3,
    upsert_fields: [:slug, :group_id],
    upsert_identity: :unique_slug
  )

# Helper functions for relative dates
today = DateTime.utc_now() |> DateTime.truncate(:second)
days_from_today = fn days -> DateTime.add(today, days * 86400, :second) end

time_on_day = fn date, hour, minute ->
  date
  |> DateTime.add(hour * 3600 + minute * 60, :second)
  |> DateTime.truncate(:second)
end

# Events for Spitex Bemeda
%{records: _medical_events, status: :success} =
  bulk_create.(
    Accounts.Event,
    [
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(2), 8, 0),
        dtend: time_on_day.(days_from_today.(2), 9, 30),
        summary: "Morning patient visit - Frau Schmidt"
      },
      %{
        activity_id: administer_medication.id,
        user_id: heidi.id,
        dtstart: time_on_day.(days_from_today.(2), 10, 0),
        dtend: time_on_day.(days_from_today.(2), 11, 0),
        summary: "Medication administration - Herr Meier"
      }
    ],
    actor: denis,
    tenant: organisation_1,
    upsert_identity: nil
  )

# Events for ASA Security
%{records: _security_events, status: :success} =
  bulk_create.(
    Accounts.Event,
    [
      %{
        activity_id: surveillance_building.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(2), 20, 0),
        dtend: time_on_day.(days_from_today.(3), 4, 0),
        summary: "Night shift - Building A"
      }
    ],
    actor: ben,
    tenant: organisation_2,
    upsert_identity: nil
  )

# Events for 3Stones
%{records: _dev_events, status: :success} =
  bulk_create.(
    Accounts.Event,
    [
      %{
        activity_id: ui_design.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(3), 9, 0),
        dtend: time_on_day.(days_from_today.(3), 10, 30),
        summary: "Sprint Planning Meeting"
      }
    ],
    actor: tim,
    tenant: organisation_3,
    upsert_identity: nil
  )

# Additional events for Spitex Bemeda with varied durations over two weeks
%{records: _additional_medical_events, status: :success} =
  bulk_create.(
    Accounts.Event,
    [
      # Week 1
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-2), 8, 0),
        dtend: time_on_day.(days_from_today.(-2), 8, 1),
        summary: "Quick medication check"
      },
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-2), 8, 30),
        dtend: time_on_day.(days_from_today.(-2), 10, 45),
        summary: "Extended care session - Frau Schmidt"
      },
      %{
        activity_id: health_assessment.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-2), 11, 0),
        dtend: time_on_day.(days_from_today.(-2), 11, 30),
        summary: "Vital signs check - Herr Weber"
      },
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-2), 13, 0),
        dtend: time_on_day.(days_from_today.(-2), 15, 30),
        summary: "Afternoon rounds"
      },
      # Week 1 - Day 2
      %{
        activity_id: administer_medication.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-1), 8, 15),
        dtend: time_on_day.(days_from_today.(-1), 8, 45),
        summary: "Morning medication round"
      },
      %{
        activity_id: follow_up_visit.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-1), 9, 0),
        dtend: time_on_day.(days_from_today.(-1), 9, 5),
        summary: "Quick check-in call"
      },
      # Edge case: Forgotten to stop tracking
      %{
        activity_id: health_assessment.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(-1), 10, 0),
        dtend: time_on_day.(days_from_today.(0), 17, 45),
        summary: "Patient documentation (tracking error)"
      },
      # Week 2
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(5), 8, 0),
        dtend: time_on_day.(days_from_today.(5), 11, 0),
        summary: "Morning patient visits"
      },
      %{
        activity_id: administer_medication.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(5), 13, 0),
        dtend: time_on_day.(days_from_today.(5), 13, 15),
        summary: "Medication review"
      },
      %{
        activity_id: follow_up_visit.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(6), 9, 0),
        dtend: time_on_day.(days_from_today.(6), 9, 45),
        summary: "Team meeting"
      },
      %{
        activity_id: follow_up_visit.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(6), 10, 0),
        dtend: time_on_day.(days_from_today.(6), 10, 2),
        summary: "Quick phone call"
      },
      %{
        activity_id: health_assessment.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(7), 8, 30),
        dtend: time_on_day.(days_from_today.(7), 11, 30),
        summary: "Complex care case"
      }
    ],
    actor: denis,
    tenant: organisation_1,
    upsert_identity: nil
  )
