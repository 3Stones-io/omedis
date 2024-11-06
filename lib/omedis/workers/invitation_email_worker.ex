defmodule Omedis.Workers.InvitationEmailWorker do
  @moduledoc false
  use Oban.Worker, queue: :invitation

  use OmedisWeb, :verified_routes

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{"actor_id" => actor_id, "tenant_id" => tenant_id, "id" => invitation_id} = args

    with {:ok, actor} <- Ash.get(User, actor_id),
         {:ok, tenant} <- Ash.get(Tenant, tenant_id, actor: actor),
         {:ok, invitation} <-
           Ash.get(Invitation, invitation_id, actor: actor, tenant: tenant, load: [:tenant]) do
      url = static_url_fun().(~p"/tenants/#{tenant.slug}/invitations/#{invitation.id}")

      Omedis.Accounts.deliver_invitation_email(invitation, url)
    end

    :ok
  end

  defp static_url_fun, do: &static_url(OmedisWeb.Endpoint, &1)
end
