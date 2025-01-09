defmodule OmedisWeb.Plugs.CurrentOrganisation do
  @moduledoc """
  This plug is used to assign the current organisation to the conn.
  """
  import Plug.Conn

  alias Omedis.Accounts

  def init(_opts), do: nil

  def call(conn, _opts) do
    current_organisation =
      with %Accounts.User{current_organisation_id: current_organisation_id}
           when not is_nil(current_organisation_id) <-
             conn.assigns[:current_user],
           {:ok, organisation} <-
             Accounts.get_organisation_by_id(current_organisation_id,
               actor: conn.assigns.current_user
             ) do
        organisation
      else
        _ ->
          nil
      end

    assign(conn, :current_organisation, current_organisation)
  end
end
