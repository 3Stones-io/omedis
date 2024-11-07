defmodule OmedisWeb.Plugs.OrganisationsCount do
  @moduledoc """
  This plug is used to fetch the organisations count from the database.
  """

  import Plug.Conn

  require Ash.Query

  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  def init(_opts), do: nil

  def call(conn, _opts) do
    organisations_count =
      case conn.assigns[:current_user] do
        %User{} = user ->
          Ash.count!(Organisation, actor: user)

        _ ->
          0
      end

    assign(conn, :organisations_count, organisations_count)
  end
end
