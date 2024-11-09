defmodule Omedis.Workers.InvitationEmailWorker do
  @moduledoc false
  use Oban.Worker, queue: :invitation

  use OmedisWeb, :verified_routes

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{"actor_id" => actor_id, "organisation_id" => organisation_id, "id" => invitation_id} = args

    with {:ok, actor} <- Ash.get(User, actor_id, authorize?: false),
         {:ok, organisation} <- Ash.get(Organisation, organisation_id, actor: actor),
         {:ok, invitation} <-
           Ash.get(Invitation, invitation_id,
             actor: actor,
             tenant: organisation,
             load: [:organisation]
           ) do
      url =
        static_url(
          OmedisWeb.Endpoint,
          ~p"/organisations/#{organisation}/invitations/#{invitation}"
        )

      Omedis.Accounts.deliver_invitation_email(invitation, url)
    end

    :ok
  end
end
