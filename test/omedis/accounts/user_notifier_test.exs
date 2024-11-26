defmodule Omedis.Accounts.UserNotifierTest do
  use Omedis.DataCase, async: true

  import Mox
  import Omedis.Fixtures

  require Ash.Query

  setup :verify_on_exit!

  setup do
    {:ok, user} = create_user()
    {:ok, organisation} = create_organisation(%{owner_id: user.id})
    {:ok, group} = create_group(organisation)

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "Invitation",
        create: true,
        group_id: group.id
      })

    {:ok, _} =
      create_access_right(organisation, %{
        resource_name: "organisation",
        create: true,
        group_id: group.id
      })

    %{
      group: group,
      organisation: organisation,
      user: user
    }
  end

  describe "deliver_invitation_email/2" do
    test "sends an invitation email",
         %{
           group: group,
           organisation: organisation,
           user: user
         } do
      # Triggered by create_event/2 fixture
      expect(
        Omedis.Accounts.UserNotifier.ClientMock,
        :deliver_invitation_email,
        fn _invitation, _url ->
          {:ok, %Swoosh.Email{}}
        end
      )

      {:ok, invitation} =
        create_invitation(organisation, %{
          creator_id: user.id,
          groups: [group.id]
        })

      # Triggered by deliver_invitation_email/2
      expect(
        Omedis.Accounts.UserNotifier.ClientMock,
        :deliver_invitation_email,
        fn _invitation, url ->
          assert url == "INVITATION_URL"
          {:ok, %Swoosh.Email{}}
        end
      )

      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")
    end

    test "sends an invitation email in the correct language",
         %{
           group: group,
           organisation: organisation,
           user: user
         } do
      # Triggered by create_event/2 fixture
      expect(
        Omedis.Accounts.UserNotifier.ClientMock,
        :deliver_invitation_email,
        fn _invitation, _url ->
          {:ok, %Swoosh.Email{}}
        end
      )

      {:ok, invitation} =
        create_invitation(organisation, %{
          creator_id: user.id,
          groups: [group.id],
          language: "fr"
        })

      invitation = Ash.load!(invitation, :organisation, authorize?: false)

      # Triggered by deliver_invitation_email/2
      expect(
        Omedis.Accounts.UserNotifier.ClientMock,
        :deliver_invitation_email,
        fn _invitation, url ->
          assert url == "INVITATION_URL"
          {:ok, %Swoosh.Email{}}
        end
      )

      Omedis.Accounts.deliver_invitation_email(invitation, "INVITATION_URL")
    end
  end
end
