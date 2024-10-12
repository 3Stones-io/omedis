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

case Ash.read(Tenant) do
  {:ok, []} ->
    Tenant.create!(%{
      city: "Dummy City",
      country: "Dummy republic",
      name: "Initial Tenant",
      slug: "initial-tenant",
      street: "Dummy Street",
      zip_code: "12345"
    })

  {:ok, _tenants} ->
    IO.puts("Tenants already exist. Skipping initial tenant creation.")
end
