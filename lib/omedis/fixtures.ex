defmodule Omedis.Fixtures do
  @moduledoc """
  Fixtures for the Omedis system.
  """

  alias Omedis.Accounts

  def create_access_right(organisation, attrs \\ %{}) do
    fixture(Accounts.AccessRight, organisation, attrs)
  end

  def create_group(organisation, attrs \\ %{}) do
    fixture(Accounts.Group, organisation, attrs)
  end

  def create_group_membership(organisation, attrs \\ %{}) do
    fixture(Accounts.GroupMembership, organisation, attrs)
  end

  def create_activity(organisation, attrs \\ %{}) do
    fixture(Accounts.Activity, organisation, attrs)
  end

  def create_log_entry(organisation, attrs \\ %{}) do
    fixture(Accounts.LogEntry, organisation, attrs)
  end

  def create_invitation(organisation, attrs \\ %{}) do
    fixture(Accounts.Invitation, organisation, attrs)
  end

  def create_invitation_group(organisation, attrs \\ %{}) do
    fixture(Accounts.InvitationGroup, organisation, attrs)
  end

  def create_project(organisation, attrs \\ %{}) do
    fixture(Accounts.Project, organisation, attrs)
  end

  def create_organisation(attrs \\ %{}) do
    attrs = set_attrs(Accounts.Organisation, nil, attrs)

    Ash.create(Accounts.Organisation, attrs, authorize?: false)
  end

  def create_user(attrs \\ %{}) do
    attrs = set_attrs(Accounts.User, nil, attrs)

    Ash.create(Accounts.User, attrs, authorize?: false)
  end

  def attrs_for(Accounts.AccessRight, organisation) do
    %{
      create: Enum.random([true, false]),
      group_id: fn ->
        {:ok, group} = create_group(organisation)
        group.id
      end,
      read: Enum.random([true, false]),
      resource_name: Enum.random(["Organisation"]),
      update: Enum.random([true, false]),
      write: Enum.random([true, false])
    }
  end

  def attrs_for(Accounts.Group, _organisation) do
    %{
      name: Faker.Company.name(),
      slug: Faker.Lorem.word() <> "-#{Ecto.UUID.generate()}"
    }
  end

  def attrs_for(Accounts.GroupMembership, organisation) do
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

  def attrs_for(Accounts.Activity, organisation) do
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
      end,
      slug: Faker.Lorem.word() <> "-#{Faker.random_between(1000, 9999)}"
    }
  end

  def attrs_for(Accounts.LogEntry, organisation) do
    %{
      end_at: ~T[18:00:00],
      activity_id: fn ->
        {:ok, activity} = create_activity(organisation)
        activity.id
      end,
      start_at: ~T[08:00:00],
      user_id: fn ->
        {:ok, user} = create_user()
        user.id
      end
    }
  end

  def attrs_for(Accounts.Invitation, _organisation) do
    %{
      creator_id: fn ->
        {:ok, user} = create_user()
        user.id
      end,
      email: Faker.Internet.email(),
      groups: [],
      language: "en"
    }
  end

  def attrs_for(Accounts.InvitationGroup, organisation) do
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
      slug: Faker.Lorem.word() <> "-#{Ecto.UUID.generate()}",
      street: Faker.Address.street_address(),
      zip_code: Faker.Address.zip_code()
    }
  end

  def attrs_for(Accounts.Project, _organisation) do
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

  defp fixture(module, organisation, attrs) do
    attrs = set_attrs(module, organisation, attrs)

    Ash.create(module, attrs, authorize?: false, tenant: organisation)
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
