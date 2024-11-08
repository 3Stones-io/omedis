defmodule Omedis.Accounts.InvitationTest do
  use Omedis.DataCase, async: true

  import Omedis.Fixtures

  alias Omedis.Accounts.Invitation

  @params %{email: "test@example.com", language: "en"}

  setup do
    {:ok, owner} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: owner.id})
    {:ok, authorized_user} = create_user()
    {:ok, group} = create_group(%{organisation_id: organisation.id})
    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, access_right} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Invitation",
        organisation_id: organisation.id,
        write: true
      })

    %{
      access_right: access_right,
      authorized_user: authorized_user,
      owner: owner,
      organisation: organisation,
      group: group
    }
  end

  describe "by_id/2" do
    test "organisation owner can access an invitation by id", %{
      organisation: organisation,
      owner: organisation_owner
    } do
      params =
        Map.merge(@params, %{creator_id: organisation_owner.id, organisation_id: organisation.id})

      {:ok, invitation} =
        Invitation.create(params, actor: organisation_owner, tenant: organisation)

      assert {:ok, invitation_from_db} =
               Invitation.by_id(invitation.id,
                 actor: organisation_owner,
                 tenant: organisation
               )

      assert invitation.id == invitation_from_db.id
    end

    test "authorized user can access an invitation by id", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      params =
        Map.merge(@params, %{creator_id: authorized_user.id, organisation_id: organisation.id})

      {:ok, invitation} =
        Invitation.create(params, actor: authorized_user, tenant: organisation)

      assert {:ok, invitation_from_db} =
               Invitation.by_id(invitation.id, actor: authorized_user, tenant: organisation)

      assert invitation.id == invitation_from_db.id
    end

    test "unauthorized user cannot access an invitation by id", %{
      access_right: access_right,
      authorized_user: user,
      organisation: organisation
    } do
      params = Map.merge(@params, %{creator_id: user.id, organisation_id: organisation.id})
      {:ok, invitation} = Invitation.create(params, actor: user, tenant: organisation)

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: user, tenant: organisation)
    end
  end

  describe "destroy/2" do
    test "organisation owner can destroy an invitation", %{
      organisation: organisation,
      owner: organisation_owner
    } do
      params =
        Map.merge(@params, %{creator_id: organisation_owner.id, organisation_id: organisation.id})

      {:ok, invitation} =
        Invitation.create(params, actor: organisation_owner, tenant: organisation)

      assert :ok = Invitation.destroy(invitation, actor: organisation_owner, tenant: organisation)
    end

    test "authorized user can destroy an invitation", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      params =
        Map.merge(@params, %{creator_id: authorized_user.id, organisation_id: organisation.id})

      {:ok, invitation} = Invitation.create(params, actor: authorized_user, tenant: organisation)
      assert :ok = Invitation.destroy(invitation, actor: authorized_user, tenant: organisation)
    end

    test "unauthorized user cannot destroy an invitation", %{
      access_right: access_right,
      authorized_user: authorized_user,
      organisation: organisation
    } do
      params =
        Map.merge(@params, %{creator_id: authorized_user.id, organisation_id: organisation.id})

      {:ok, invitation} = Invitation.create(params, actor: authorized_user, tenant: organisation)

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:error, %Ash.Error.Forbidden{}} =
               Invitation.destroy(invitation, actor: authorized_user, tenant: organisation)
    end
  end

  describe "list_paginated/2" do
    test "returns invitations for the organisation owner", %{
      organisation: organisation,
      owner: organisation_owner
    } do
      creator_id = organisation_owner.id
      params = Map.merge(@params, %{creator_id: creator_id, organisation_id: organisation.id})

      {:ok, invitation} =
        Invitation.create(params, actor: organisation_owner, tenant: organisation)

      assert {:ok, %{results: results, count: 1}} =
               Invitation.list_paginated(
                 actor: organisation_owner,
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )

      assert hd(results).id == invitation.id
    end

    test "returns invitations for the authorized user", %{
      authorized_user: authorized_user,
      organisation: organisation
    } do
      creator_id = authorized_user.id

      for i <- 1..15 do
        params =
          Map.merge(@params, %{
            creator_id: creator_id,
            email: "test#{i}@example.com",
            organisation_id: organisation.id
          })

        {:ok, _} = Invitation.create(params, actor: authorized_user, tenant: organisation)
      end

      assert {:ok, %{results: results, count: 15}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 10, offset: 0],
                 tenant: organisation
               )

      assert length(results) == 10

      # Second page
      assert {:ok, %{results: more_results}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 10, offset: 10],
                 tenant: organisation
               )

      assert length(more_results) == 5
    end

    test "sorts invitations by inserted_at", %{
      organisation: organisation,
      owner: organisation_owner
    } do
      invitations =
        for i <- 1..3 do
          {:ok, invitation} =
            create_invitation(%{
              creator_id: organisation_owner.id,
              organisation_id: organisation.id
            })

          invitation
          |> Ash.Changeset.for_update(:update, %{inserted_at: time_after(-i * 12_000)},
            authorize?: false
          )
          |> Ash.update!()
        end

      assert {:ok, %{results: results}} =
               Invitation.list_paginated(%{sort_order: :asc},
                 actor: organisation_owner,
                 tenant: organisation
               )

      assert Enum.map(results, & &1.inserted_at) ==
               invitations |> Enum.map(& &1.inserted_at) |> Enum.reverse()
    end

    test "does not return invitations if user is unauthorized", %{
      access_right: access_right,
      authorized_user: authorized_user,
      organisation: organisation
    } do
      creator_id = authorized_user.id

      for i <- 1..15 do
        params =
          Map.merge(@params, %{
            creator_id: creator_id,
            email: "test#{i}@example.com",
            organisation_id: organisation.id
          })

        {:ok, _} = Invitation.create(params, actor: authorized_user, tenant: organisation)
      end

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:ok, %{results: [], count: 0}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 20, offset: 0],
                 tenant: organisation
               )
    end
  end
end
