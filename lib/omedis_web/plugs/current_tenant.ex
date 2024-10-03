defmodule OmedisWeb.Plugs.CurrentTenant do
  @moduledoc """
  This plug is used to assign the current tenant to the conn.
  """
  import Plug.Conn

  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.User

  def init(_opts), do: nil

  def call(conn, _opts) do
    current_tenant =
      with %User{current_tenant_id: current_tenant_id} when not is_nil(current_tenant_id) <-
             conn.assigns[:current_user],
           {:ok, tenant} <- Tenant.by_id(current_tenant_id) do
        tenant
      else
        _ ->
          nil
      end

    assign(conn, :current_tenant, current_tenant)
  end
end
