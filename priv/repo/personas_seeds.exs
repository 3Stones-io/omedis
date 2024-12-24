import Omedis.Fixtures

require Ash.Query

alias Omedis.Accounts
alias Omedis.Groups
alias Omedis.Invitations
alias Omedis.Projects
alias Omedis.TimeTracking

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

get_organisation = fn owner_id ->
  Accounts.Organisation
  |> Ash.Query.filter(owner_id: owner_id)
  |> Ash.read_one!(authorize?: false)
end

%{records: [denis, ben, tim], status: :success} =
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
      # ASA Security
      %{
        email: "ben.hall@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("bensecure"),
        first_name: "Ben",
        last_name: "Hall"
      },
      # 3Stones
      %{
        email: "tim.davis@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("timrocks"),
        first_name: "Tim",
        last_name: "Davis"
      }
    ],
    upsert_identity: :unique_email
  )

organisation_1 = get_organisation.(denis.id)
organisation_2 = get_organisation.(ben.id)
organisation_3 = get_organisation.(tim.id)

%{records: _invitations, status: :success} =
  sequential_create.(
    Invitations.Invitation,
    [
      %{
        creator_id: denis.id,
        email: "heidi@spitex-bemeda.ch",
        language: "en"
      },
      %{
        creator_id: denis.id,
        email: "fatima.khan@spitex-bemeda.ch",
        language: "en"
      }
    ],
    tenant: organisation_1,
    existence_check_keys: [:email]
  )

%{records: [heidi, _fatima], status: :success} =
  sequential_create.(
    Accounts.User,
    [
      %{
        email: "heidi@spitex-bemeda.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Heidi",
        last_name: "Smith"
      },
      %{
        email: "fatima.khan@spitex-bemeda.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Fatima",
        last_name: "Khan"
      }
    ],
    existence_check_keys: [:email]
  )

%{records: _invitations, status: :success} =
  sequential_create.(
    Invitations.Invitation,
    [
      %{
        creator_id: ben.id,
        email: "sarah.jones@asa-security.ch",
        language: "en"
      },
      %{
        creator_id: ben.id,
        email: "lena.meyer@asa-security.ch",
        language: "en"
      }
    ],
    tenant: organisation_2,
    authorize?: false,
    existence_check_keys: [:email]
  )

%{records: [sarah, lena], status: :success} =
  sequential_create.(
    Accounts.User,
    [
      %{
        email: "sarah.jones@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Sarah",
        last_name: "Jones"
      },
      %{
        email: "lena.meyer@asa-security.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Lena",
        last_name: "Meyer"
      }
    ],
    existence_check_keys: [:email]
  )

%{records: _invitations, status: :success} =
  sequential_create.(
    Invitations.Invitation,
    [
      %{
        creator_id: tim.id,
        email: "anna.wilson@3stones.ch",
        language: "en"
      },
      %{
        creator_id: tim.id,
        email: "marc.brown@3stones.ch",
        language: "en"
      }
    ],
    tenant: organisation_3,
    existence_check_keys: [:email]
  )

%{records: [anna, marc], status: :success} =
  sequential_create.(
    Accounts.User,
    [
      %{
        email: "anna.wilson@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Anna",
        last_name: "Wilson"
      },
      %{
        email: "marc.brown@3stones.ch",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Marc",
        last_name: "Brown"
      }
    ],
    existence_check_keys: [:email]
  )

%{records: [group_1, group_2], status: :success} =
  bulk_create.(
    Groups.Group,
    [
      %{name: "Demo Group", slug: "demo-group"},
      %{name: "Demo Group 2", slug: "demo-group2"}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: [security_group], status: :success} =
  bulk_create.(
    Groups.Group,
    [
      %{name: "Security Team", slug: "security-team"}
    ],
    tenant: organisation_2,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: [dev_group], status: :success} =
  bulk_create.(
    Groups.Group,
    [
      %{name: "Development Team", slug: "dev-team"}
    ],
    tenant: organisation_3,
    upsert_identity: :unique_slug_per_organisation
  )

%{records: _records, status: :success} =
  bulk_create.(
    Groups.GroupMembership,
    [
      %{group_id: group_1.id, user_id: denis.id},
      %{group_id: group_2.id, user_id: heidi.id}
    ],
    tenant: organisation_1,
    upsert_identity: :unique_group_membership
  )

%{records: [medical_support, _frau_schmidt, _herr_meier], status: :success} =
  sequential_create.(
    Projects.Project,
    [
      %{name: "Medical Support", position: "2", organisation_id: organisation_1.id},
      %{name: "Frau Schmidt", position: "3", organisation_id: organisation_1.id},
      %{name: "Herr Meier", position: "4", organisation_id: organisation_1.id}
    ],
    tenant: organisation_1,
    existence_check_keys: [:name, :organisation_id]
  )

%{records: [security_operations], status: :success} =
  sequential_create.(
    Projects.Project,
    [
      %{organisation_id: organisation_2.id, name: "Security Operations", position: "2"}
    ],
    tenant: organisation_2,
    existence_check_keys: [:name, :organisation_id]
  )

%{records: [software_development], status: :success} =
  sequential_create.(
    Projects.Project,
    [
      %{organisation_id: organisation_3.id, name: "Software Development", position: "2"}
    ],
    tenant: organisation_3,
    existence_check_keys: [:name, :organisation_id]
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
    TimeTracking.Activity,
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
    existence_check_keys: [:slug, :group_id]
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
    TimeTracking.Activity,
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
    existence_check_keys: [:slug, :group_id]
  )

%{
  records: [ui_design, _modeling, _code_review, _talking_to_devs, _testing_features],
  status: :success
} =
  sequential_create.(
    TimeTracking.Activity,
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
    existence_check_keys: [:slug, :group_id]
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
  sequential_create.(
    TimeTracking.Event,
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
    existence_check_keys: [:summary]
  )

time_on_day.(days_from_today.(-2), 8, 0) |> IO.inspect(label: "dtstart::::")
time_on_day.(days_from_today.(-2), 8, 10) |> IO.inspect(label: "dtend::::")

# Events for ASA Security
%{records: _security_events, status: :success} =
  sequential_create.(
    TimeTracking.Event,
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
    existence_check_keys: [:summary]
  )

# Events for 3Stones
%{records: _dev_events, status: :success} =
  sequential_create.(
    TimeTracking.Event,
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
    existence_check_keys: [:summary]
  )

# Additional events for Spitex Bemeda with varied durations over two weeks
%{records: _additional_medical_events, status: :success} =
  sequential_create.(
    TimeTracking.Event,
    [
      # Week 1
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
      },
      # Week 2
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(8), 8, 0),
        dtend: time_on_day.(days_from_today.(8), 8, 10),
        summary: "Quick medication check"
      },
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(8), 10, 30),
        dtend: time_on_day.(days_from_today.(8), 12, 30),
        summary: "Extended care session - Frau Schmidt"
      },
      %{
        activity_id: health_assessment.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(8), 12, 31),
        dtend: time_on_day.(days_from_today.(8), 13, 30),
        summary: "Vital signs check - Herr Weber"
      },
      %{
        activity_id: visit_patient.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(8), 13, 31),
        dtend: time_on_day.(days_from_today.(8), 14, 30),
        summary: "Afternoon rounds"
      },
      %{
        activity_id: administer_medication.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(9), 8, 15),
        dtend: time_on_day.(days_from_today.(9), 8, 45),
        summary: "Morning medication round"
      },
      %{
        activity_id: follow_up_visit.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(9), 9, 0),
        dtend: time_on_day.(days_from_today.(9), 9, 5),
        summary: "Quick check-in call"
      },
      %{
        activity_id: health_assessment.id,
        user_id: denis.id,
        dtstart: time_on_day.(days_from_today.(9), 10, 0),
        dtend: time_on_day.(days_from_today.(9), 11, 45),
        summary: "Patient documentation"
      }
    ],
    actor: denis,
    tenant: organisation_1,
    existence_check_keys: [:summary]
  )
