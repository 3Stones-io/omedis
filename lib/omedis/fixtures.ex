defmodule Omedis.Fixtures do
  @moduledoc """
  Fixtures for the Omedis system.
  """

  alias Omedis.AccessRights
  alias Omedis.Accounts
  alias Omedis.Groups
  alias Omedis.Invitations
  alias Omedis.Projects
  alias Omedis.TimeTracking

  def create_access_right(organisation, attrs \\ %{}) do
    fixture(AccessRights.AccessRight, organisation, attrs)
  end

  def create_group(organisation, attrs \\ %{}) do
    fixture(Groups.Group, organisation, attrs)
  end

  def create_group_membership(organisation, attrs \\ %{}) do
    fixture(Groups.GroupMembership, organisation, attrs)
  end

  def create_activity(organisation, attrs \\ %{}) do
    fixture(TimeTracking.Activity, organisation, attrs)
  end

  def create_event(organisation, attrs \\ %{}, opts \\ []) do
    fixture(TimeTracking.Event, organisation, attrs, opts)
  end

  def create_invitation(organisation, attrs \\ %{}, opts \\ []) do
    fixture(Invitations.Invitation, organisation, attrs, opts)
  end

  def create_invitation_group(organisation, attrs \\ %{}) do
    fixture(Invitations.InvitationGroup, organisation, attrs)
  end

  def create_project(organisation, attrs \\ %{}) do
    fixture(Projects.Project, organisation, attrs)
  end

  def create_organisation(attrs \\ %{}, opts \\ []) do
    attrs = set_attrs(Accounts.Organisation, nil, attrs)
    opts = Keyword.put(opts, :authorize?, false)

    Ash.create(Accounts.Organisation, attrs, opts)
  end

  def create_user(attrs \\ %{}) do
    attrs = set_attrs(Accounts.User, nil, attrs)

    Ash.create(Accounts.User, attrs, authorize?: false)
  end

  def attrs_for(AccessRights.AccessRight, organisation) do
    %{
      create: Enum.random([true, false]),
      group_id: fn ->
        {:ok, group} = create_group(organisation)
        group.id
      end,
      read: Enum.random([true, false]),
      resource_name: Enum.random(["Organisation"]),
      update: Enum.random([true, false]),
      destroy: Enum.random([true, false])
    }
  end

  def attrs_for(Groups.Group, _organisation) do
    %{
      name: Faker.Company.name()
    }
  end

  def attrs_for(Groups.GroupMembership, organisation) do
    %{
      group_id: fn ->
        {:ok, group} = create_group(organisation)
        group.id
      end,
      user_id: fn ->
        {:ok, user} = create_user()
        user.id
      end
    }
  end

  def attrs_for(TimeTracking.Activity, organisation) do
    %{
      color_code: "#" <> Faker.Color.rgb_hex(),
      group_id: fn ->
        {:ok, group} = create_group(organisation)
        group.id
      end,
      is_default: false,
      name: Faker.Lorem.word(),
      project_id: fn ->
        {:ok, project} = create_project(organisation)
        project.id
      end
    }
  end

  def attrs_for(TimeTracking.Event, organisation) do
    %{
      activity_id: fn ->
        {:ok, activity} = create_activity(organisation)
        activity.id
      end,
      dtend: NaiveDateTime.add(NaiveDateTime.utc_now(), 60, :minute),
      dtstart: NaiveDateTime.utc_now(),
      summary: Faker.Lorem.word(),
      user_id: fn ->
        {:ok, user} = create_user()
        user.id
      end
    }
  end

  def attrs_for(Invitations.Invitation, _organisation) do
    %{
      creator_id: fn ->
        {:ok, user} = create_user()
        user.id
      end,
      email: Faker.Internet.email(),
      groups: [],
      language: "en",
      status: :pending
    }
  end

  def attrs_for(Invitations.InvitationGroup, organisation) do
    %{
      group_id: fn ->
        {:ok, group} = create_group(organisation)
        group.id
      end,
      invitation_id: fn ->
        {:ok, invitation} = create_invitation(organisation)
        invitation.id
      end
    }
  end

  def attrs_for(Accounts.Organisation, nil) do
    %{
      city: Faker.Address.city(),
      country: Faker.Address.country(),
      name: Faker.Company.name(),
      owner_id: fn ->
        {:ok, user} = create_user()
        user.id
      end,
      street: Faker.Address.street_address(),
      zip_code: Faker.Address.zip_code()
    }
  end

  def attrs_for(Projects.Project, _organisation) do
    %{
      name: Faker.Lorem.sentence(),
      position: (System.os_time(:second) + :rand.uniform(999_999_999)) |> to_string()
    }
  end

  def attrs_for(Accounts.User, nil) do
    %{
      birthdate: Faker.Date.between(~D[1950-01-01], ~D[2000-01-01]),
      email: Faker.Internet.email(),
      first_name: Faker.Person.first_name(),
      gender: Enum.random(["Male", "Female"]),
      hashed_password: Bcrypt.hash_pwd_salt("password"),
      last_name: Faker.Person.last_name()
    }
  end

  defp fixture(module, organisation, attrs, opts \\ []) do
    attrs = set_attrs(module, organisation, attrs)
    opts = opts ++ [authorize?: false, tenant: organisation]

    Ash.create(module, attrs, opts)
  end

  defp set_attrs(module, organisation, attrs) do
    module
    |> attrs_for(organisation)
    |> Map.merge(attrs)
    |> Enum.map(fn
      {key, value} when is_function(value, 0) -> {key, value.()}
      element -> element
    end)
    |> Map.new()
  end
end
