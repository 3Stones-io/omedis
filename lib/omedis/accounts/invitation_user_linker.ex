defmodule Omedis.Accounts.InvitationUserLinker do
  @moduledoc """
  A GenServer that links newly registered users with their corresponding invitations.

  When a user registers through an invitation, this GenServer automatically updates the invitation
  record to associate it with the newly created user account.
  """
  use GenServer

  require Ash.Query
  require Logger

  alias Omedis.Accounts.Invitation

  @topic "user:created"

  # PubSub events are string equivalents of resource actions
  @events ["create", "register_with_password"]

  def start_link(_opts) do
    case GenServer.start_link(__MODULE__, [], name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  @impl true
  def init(_opts) do
    :ok = OmedisWeb.Endpoint.subscribe(@topic)

    {:ok, %{}}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: event,
          topic: @topic,
          payload: %Ash.Notifier.Notification{data: user}
        },
        state
      )
      when event in @events do
    case get_pending_invitation(user.email) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, [invitation]} ->
        update_invitation(invitation, user.id)

      {:error, error} ->
        Logger.error("[InvitationUserLinker] error: #{inspect(error)}")
        {:error, error}
    end

    {:noreply, state}
  end

  defp get_pending_invitation(email) do
    Invitation
    |> Ash.Query.filter(email: email)
    |> Ash.Query.filter(expires_at > ^DateTime.utc_now())
    |> Ash.Query.filter(is_nil(user_id))
    |> Ash.read(authorize?: false)
  end

  defp update_invitation(invitation, user_id) do
    case Invitation.update(invitation, %{user_id: user_id}, authorize?: false) do
      {:ok, updated_invitation} ->
        {:ok, updated_invitation}

      {:error, error} ->
        {:error, error}
    end
  end
end
