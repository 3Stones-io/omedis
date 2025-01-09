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

alias Omedis.Accounts

case Ash.read(Accounts.Organisation, authorize?: false) do
  {:ok, []} ->
    Accounts.create_user!(%{
      email: "dummy@user.com",
      hashed_password: Bcrypt.hash_pwd_salt("password"),
      first_name: "Dummy",
      last_name: "User",
      gender: "Male",
      birthdate: "1980-01-01"
    })

  {:ok, _organisations} ->
    IO.puts("Organisations already exist. Skipping initial organisation creation.")
end
