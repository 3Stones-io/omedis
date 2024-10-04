defmodule OmedisWeb.Plugs.TenantsCount do
  @moduledoc """
  This plug is used to fetch the tenants count from the database.
  """

  import Plug.Conn

  alias Omedis.Accounts.User
  alias Plug.Conn

  def init(_opts), do: nil

  def call(%Conn{assigns: %{current_user: %User{} = user}} = conn, _opts) do
    {:ok, user_with_count} = Ash.load(user, [:tenants_count])
    assign(conn, :tenants_count, user_with_count.tenants_count)
  end

  def call(conn, _opts), do: assign(conn, :tenants_count, nil)
end
