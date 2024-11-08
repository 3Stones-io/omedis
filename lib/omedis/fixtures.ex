defmodule Omedis.Fixtures do
  @moduledoc """
  Fixtures for the Omedis system.
  """

  alias Omedis.Accounts

  def create_access_right(attrs \\ %{}) do
    fixture(Accounts.AccessRight, attrs)
  end

  def create_group(attrs \\ %{}) do
    fixture(Accounts.Group, attrs)
  end

  def create_group_membership(attrs \\ %{}) do
    fixture(Accounts.GroupMembership, attrs)
  end

  def create_activity(attrs \\ %{}) do
    fixture(Accounts.Activity, attrs)
  end

  def create_log_entry(attrs \\ %{}) do
    fixture(Accounts.LogEntry, attrs)
  end

  def create_invitation(attrs \\ %{}) do
    fixture(Accounts.Invitation, attrs)
  end

  def create_invitation_group(attrs \\ %{}) do
    fixture(Accounts.InvitationGroup, attrs)
  end

  def create_organisation(attrs \\ %{}) do
    fixture(Accounts.Organisation, attrs)
  end

  def create_project(attrs \\ %{}) do
    fixture(Accounts.Project, attrs)
  end

  def create_user(attrs \\ %{}) do
    fixture(Accounts.User, attrs)
  end

  def attrs_for(Accounts.AccessRight) do
    %{
      create: Enum.random([true, false]),
      group_id: fn -> create_group().id end,
      read: Enum.random([true, false]),
      resource_name: Enum.random(["Organisation"]),
      organisation_id: fn -> create_organisation().id end,
      update: Enum.random([true, false]),
      write: Enum.random([true, false])
    }
  end

  def attrs_for(Accounts.Group) do
    %{
      name: Faker.Company.name(),
      slug: Faker.Lorem.word() <> "-#{Ecto.UUID.generate()}"
    }
  end

  def attrs_for(Accounts.GroupMembership) do
    %{
      group_id: fn -> create_group().id end,
      user_id: fn -> create_user().id end
    }
  end

  def attrs_for(Accounts.Activity) do
    %{
      color_code: "#" <> Faker.Color.rgb_hex(),
      group_id: fn -> create_group().id end,
      is_default: false,
      name: Faker.Lorem.word(),
      project_id: fn -> create_project().id end,
      slug: Faker.Lorem.word() <> "-#{Faker.random_between(1000, 9999)}"
    }
  end

  def attrs_for(Accounts.LogEntry) do
    %{
      end_at: ~T[18:00:00],
      activity_id: fn -> create_activity().id end,
      start_at: ~T[08:00:00],
      organisation_id: fn -> create_organisation().id end,
      user_id: fn -> create_user().id end
    }
  end

  def attrs_for(Accounts.Invitation) do
    %{
      creator_id: fn -> create_user().id end,
      email: Faker.Internet.email(),
      language: "en",
      organisation_id: fn -> create_organisation().id end,
      groups: []
    }
  end

  def attrs_for(Accounts.InvitationGroup) do
    %{
      group_id: fn -> create_group().id end,
      invitation_id: fn -> create_invitation().id end
    }
  end

  def attrs_for(Accounts.Organisation) do
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

  def attrs_for(Accounts.Project) do
    %{
      name: Faker.Lorem.sentence(),
      organisation_id: fn -> create_organisation().id end,
      position: (System.os_time(:second) + :rand.uniform(1000)) |> to_string()
    }
  end

  def attrs_for(Accounts.User) do
    %{
      birthdate: Faker.Date.between(~D[1950-01-01], ~D[2000-01-01]),
      email: Faker.Internet.email(),
      first_name: Faker.Person.first_name(),
      gender: Enum.random(["Male", "Female"]),
      hashed_password: Bcrypt.hash_pwd_salt("password"),
      last_name: Faker.Person.last_name()
    }
  end

  defp fixture(module, attrs) do
    attrs =
      module
      |> attrs_for()
      |> Map.merge(attrs)
      |> Enum.map(fn
        {key, value} when is_function(value, 0) -> {key, value.()}
        element -> element
      end)
      |> Map.new()

    Ash.create(module, attrs, authorize?: false)
  end
end
