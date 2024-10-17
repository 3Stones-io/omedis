defmodule OmedisWeb.Plugs.TenantsCount do
  @moduledoc """
  This plug is used to fetch the tenants count from the database.
  """

  import Plug.Conn

  require Ash.Query

  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.User

  def init(_opts), do: nil

  def call(conn, _opts) do
    tenants_count =
      case conn.assigns[:current_user] do
        %User{id: user_id} ->
          Tenant
          |> Ash.Query.filter(
            exists(
              access_rights,
              resource_name == "tenant" and
                read == true and
                exists(group.group_users, user_id == ^user_id)
            )
          )
          |> Ash.count!(authorize?: false)

        _ ->
          0
      end

    assign(conn, :tenants_count, tenants_count)
  end
end
