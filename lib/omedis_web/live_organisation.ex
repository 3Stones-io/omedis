defmodule OmedisWeb.LiveOrganisation do
  @moduledoc """
  Helpers for assigning the current organisation in LiveViews.
  """

  use OmedisWeb, :verified_routes

  import Phoenix.Component

  require Ash.Query

  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  def on_mount(:assign_current_organisation, _params, _session, socket) do
    current_organisation =
      with %User{current_organisation_id: current_organisation_id}
           when not is_nil(current_organisation_id) <-
             socket.assigns[:current_user],
           {:ok, organisation} <-
             Organisation.by_id(current_organisation_id, actor: socket.assigns.current_user) do
        organisation
      else
        _ ->
          nil
      end

    {:cont, assign(socket, :current_organisation, current_organisation)}
  end

  def on_mount(:assign_organisations_count, _params, _session, socket) do
    organisations_count =
      case socket.assigns[:current_user] do
        %User{} = user ->
          Ash.count!(Organisation, actor: user)

        _ ->
          0
      end

    {:cont, assign(socket, :organisations_count, organisations_count)}
  end
end
