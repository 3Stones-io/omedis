defmodule Omedis.Chats.ChatTest do
  use Omedis.DataCase, async: true

  import Omedis.TestUtils

  alias Omedis.Chats.ChatRoom

  setup do
    {:ok, user} = create_user()
    organisation = fetch_users_organisation(user.id)
    {:ok, authorized_user} = create_user()

    %{user: user, organisation: organisation, authorized_user: authorized_user}
  end

  describe "create_chat_room/2" do
    test "organisation owner can create a chat room", %{user: user, organisation: organisation} do
      assert %ChatRoom{} =
               chat_room =
               ChatRoom.create!(
                 %{
                   name: "Test Chat Room",
                   organisation_id: organisation.id,
                   user_id: user.id
                 },
                 actor: user,
                 tenant: organisation
               )

      assert chat_room.user_id == user.id
      assert chat_room.organisation_id == organisation.id
    end
  end
end
