defmodule Omedis.Workers.InvitationExpirationWorkerTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Invitation
  alias Omedis.Workers.InvitationExpirationWorker

  setup do
    {:ok, user} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: user.id}, actor: user)
    {:ok, group} = create_group(organisation)

    {:ok, invitation} =
      create_invitation(organisation, %{
        creator_id: user.id,
        groups: [group.id]
      })

    %{invitation: invitation}
  end

  describe "perform/1" do
    test "expires a pending invitation", %{invitation: invitation} do
      assert invitation.status == :pending

      assert :ok = perform_job(InvitationExpirationWorker, %{"invitation_id" => invitation.id})

      {:ok, updated_invitation} = Invitation.by_id(invitation.id, authorize?: false)
      assert updated_invitation.status == :expired
    end

    test "handles already expired invitations gracefully", %{invitation: invitation} do
      # First expire the invitation
      {:ok, _} = Invitation.expire(invitation, authorize?: false)

      # Try to expire it again through the worker
      assert :ok = perform_job(InvitationExpirationWorker, %{"invitation_id" => invitation.id})

      {:ok, updated_invitation} = Invitation.by_id(invitation.id, authorize?: false)
      assert updated_invitation.status == :expired
    end

    test "handles already accepted invitations gracefully", %{invitation: invitation} do
      # First accept the invitation
      {:ok, _} = Invitation.accept(invitation, authorize?: false)

      # Try to expire it through the worker
      assert :ok = perform_job(InvitationExpirationWorker, %{"invitation_id" => invitation.id})

      {:ok, updated_invitation} = Invitation.by_id(invitation.id, authorize?: false)
      assert updated_invitation.status == :accepted
    end

    test "handles non-existent invitations gracefully" do
      assert :ok =
               perform_job(InvitationExpirationWorker, %{
                 "invitation_id" => Ash.UUID.generate()
               })
    end
  end
end
