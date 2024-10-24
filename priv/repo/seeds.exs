# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Omedis.Repo.insert!(%Omedis.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Omedis.Accounts.Tenant
alias Omedis.Accounts.User

case Ash.read(Tenant, authorize?: false) do
  {:ok, []} ->
    user =
      User.create!(%{
        email: "dummy@user.com",
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        first_name: "Dummy",
        last_name: "User",
        gender: "Male",
        birthdate: "1980-01-01"
      })

    Tenant.create!(
      %{
        city: "Dummy City",
        country: "Dummy republic",
        name: "Initial Tenant",
        slug: "initial-tenant",
        street: "Dummy Street",
        owner_id: user.id,
        zip_code: "12345"
      },
      authorize?: false
    )

  {:ok, _tenants} ->
    IO.puts("Tenants already exist. Skipping initial tenant creation.")
end
