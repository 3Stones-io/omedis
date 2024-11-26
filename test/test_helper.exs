Mox.defmock(Omedis.Accounts.UserNotifier.ClientMock,
  for: Omedis.Accounts.UserNotifier.Behaviour
)

Application.put_env(:omedis, :user_notifier, Omedis.Accounts.UserNotifier.ClientMock)

ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Omedis.Repo, :manual)
