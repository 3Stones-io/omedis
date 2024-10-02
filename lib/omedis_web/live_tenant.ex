defmodule OmedisWeb.LiveTenant do
  @moduledoc """
  Helpers for assigning the current tenant in LiveViews.
  """

  use OmedisWeb, :verified_routes

  import Phoenix.Component

  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.User

  def on_mount(:assign_current_tenant, _params, _session, socket) do
    current_tenant =
      with %User{current_tenant_id: current_tenant_id} when not is_nil(current_tenant_id) <-
             socket.assigns[:current_user],
           {:ok, tenant} <- Tenant.by_id(current_tenant_id) do
        tenant
      else
        _ ->
          nil
      end

    {:cont, assign(socket, :current_tenant, current_tenant)}
  end
end
