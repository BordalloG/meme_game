defmodule MemeGame.ClientServerTest do
   use MemeGame.DataCase
   use ExUnit.Case, async: true
   
   import MemeGame.Factory

   setup do
        game = build(:game)
        {:ok, %{game: game}}
   end

    describe "broadcast_game_update/1" do
        test "should broadcast the game as payload and 'update' as event to the pubsub", %{game: game} do
           Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))

           MemeGame.GameServer.broadcast_game_update(game)

           assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: ^game}
        end
   end
end