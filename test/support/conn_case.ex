defmodule OmedisWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use OmedisWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Omedis.Fixtures

  alias AshAuthentication.Phoenix.Plug, as: AshAuthenticationPhoenixPlug
  alias Omedis.Accounts

  using do
    quote do
      # The default endpoint for testing
      @endpoint OmedisWeb.Endpoint

      use OmedisWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Omedis.Fixtures
      import OmedisWeb.ConnCase

      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
    end
  end

  setup tags do
    Omedis.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    {:ok, user} = create_user()
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(%Plug.Conn{} = conn, %Accounts.User{} = user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> AshAuthenticationPhoenixPlug.store_in_session(user)
    |> AshAuthenticationPhoenixPlug.load_from_session(otp_app: :omedis)
    |> Plug.Conn.assign(:current_user, user)
  end
end
