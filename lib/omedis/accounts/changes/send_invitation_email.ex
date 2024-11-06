defmodule Omedis.Accounts.Changes.SendInvitationEmail do
  @moduledoc false
  use Ash.Resource.Change

  alias Omedis.Workers.InvitationEmailWorker

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_transaction(changeset, fn
      _changeset, {:ok, result} ->
        {:ok, _job} =
          %{"id" => result.id, "tenant_id" => result.tenant_id, "actor_id" => result.creator_id}
          |> InvitationEmailWorker.new()
          |> Oban.insert()

        {:ok, result}

      _changeset, {:error, error} ->
        {:error, error}
    end)
  end
end
