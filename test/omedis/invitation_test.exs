defmodule Omedis.Accounts.InvitationTest do
  use Omedis.DataCase, async: true

  alias Omedis.Accounts.Invitation

  @params %{email: "test@example.com", language: "en"}

  setup do
    {:ok, owner} = create_user()
    {:ok, tenant} = create_tenant(%{owner_id: owner.id})
    {:ok, authorized_user} = create_user()
    {:ok, group} = create_group(%{tenant_id: tenant.id})
    {:ok, _} = create_group_membership(%{group_id: group.id, user_id: authorized_user.id})

    {:ok, access_right} =
      create_access_right(%{
        group_id: group.id,
        read: true,
        resource_name: "Invitation",
        tenant_id: tenant.id,
        write: true
      })

    %{
      access_right: access_right,
      authorized_user: authorized_user,
      owner: owner,
      tenant: tenant,
      group: group
    }
  end

  describe "by_id/2" do
    test "tenant owner can access an invitation by id", %{tenant: tenant, owner: tenant_owner} do
      params = Map.merge(@params, %{creator_id: tenant_owner.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: tenant_owner, tenant: tenant)

      assert {:ok, invitation_from_db} =
               Invitation.by_id(invitation.id, actor: tenant_owner, tenant: tenant)

      assert invitation.id == invitation_from_db.id
    end

    test "authorized user can access an invitation by id", %{
      authorized_user: authorized_user,
      tenant: tenant
    } do
      params = Map.merge(@params, %{creator_id: authorized_user.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: authorized_user, tenant: tenant)

      assert {:ok, invitation_from_db} =
               Invitation.by_id(invitation.id, actor: authorized_user, tenant: tenant)

      assert invitation.id == invitation_from_db.id
    end

    test "unauthorized user cannot access an invitation by id", %{
      access_right: access_right,
      authorized_user: user,
      tenant: tenant
    } do
      params = Map.merge(@params, %{creator_id: user.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: user, tenant: tenant)

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Invitation.by_id(invitation.id, actor: user, tenant: tenant)
    end
  end

  describe "destroy/2" do
    test "tenant owner can destroy an invitation", %{tenant: tenant, owner: tenant_owner} do
      params = Map.merge(@params, %{creator_id: tenant_owner.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: tenant_owner, tenant: tenant)
      assert :ok = Invitation.destroy(invitation, actor: tenant_owner, tenant: tenant)
    end

    test "authorized user can destroy an invitation", %{
      tenant: tenant,
      authorized_user: authorized_user
    } do
      params = Map.merge(@params, %{creator_id: authorized_user.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: authorized_user, tenant: tenant)
      assert :ok = Invitation.destroy(invitation, actor: authorized_user, tenant: tenant)
    end

    test "unauthorized user cannot destroy an invitation", %{
      access_right: access_right,
      authorized_user: authorized_user,
      tenant: tenant
    } do
      params = Map.merge(@params, %{creator_id: authorized_user.id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: authorized_user, tenant: tenant)

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:error, %Ash.Error.Forbidden{}} =
               Invitation.destroy(invitation, actor: authorized_user, tenant: tenant)
    end
  end

  describe "list_paginated/2" do
    test "returns invitations for the tenant owner", %{tenant: tenant, owner: tenant_owner} do
      creator_id = tenant_owner.id
      params = Map.merge(@params, %{creator_id: creator_id, tenant_id: tenant.id})
      {:ok, invitation} = Invitation.create(params, actor: tenant_owner, tenant: tenant)

      assert {:ok, %{results: results, count: 1}} =
               Invitation.list_paginated(
                 actor: tenant_owner,
                 page: [limit: 10, offset: 0],
                 tenant: tenant
               )

      assert hd(results).id == invitation.id
    end

    test "returns invitations for the authorized user", %{
      tenant: tenant,
      authorized_user: authorized_user
    } do
      creator_id = authorized_user.id

      for i <- 1..15 do
        params =
          Map.merge(@params, %{
            creator_id: creator_id,
            email: "test#{i}@example.com",
            tenant_id: tenant.id
          })

        {:ok, _} = Invitation.create(params, actor: authorized_user, tenant: tenant)
      end

      assert {:ok, %{results: results, count: 15}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 10, offset: 0],
                 tenant: tenant
               )

      assert length(results) == 10

      # Second page
      assert {:ok, %{results: more_results}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 10, offset: 10],
                 tenant: tenant
               )

      assert length(more_results) == 5
    end

    test "does not return invitations if user is unauthorized", %{
      access_right: access_right,
      authorized_user: authorized_user,
      tenant: tenant
    } do
      creator_id = authorized_user.id

      for i <- 1..15 do
        params =
          Map.merge(@params, %{
            creator_id: creator_id,
            email: "test#{i}@example.com",
            tenant_id: tenant.id
          })

        {:ok, _} = Invitation.create(params, actor: authorized_user, tenant: tenant)
      end

      # Remove access rights for the user
      Ash.destroy!(access_right)

      assert {:ok, %{results: [], count: 0}} =
               Invitation.list_paginated(
                 actor: authorized_user,
                 page: [limit: 20, offset: 0],
                 tenant: tenant
               )
    end
  end
end
