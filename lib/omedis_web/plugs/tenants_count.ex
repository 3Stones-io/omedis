defmodule OmedisWeb.Plugs.TenantsCount do
  @moduledoc """
  This plug is used to fetch the tenants count from the database.
  """

  import Plug.Conn

  alias Omedis.Accounts.Tenant

  def init(_opts), do: nil

  def call(conn, _opts) do
    {:ok, tenant_count} = Ash.count(Tenant)
    assign(conn, :tenants_count, tenant_count)
  end
end
